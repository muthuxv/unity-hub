package services

import (
    "context"
    "encoding/json"
    "errors"
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "os"
    "time"
    "app/controllers"
    "app/db"
    "app/db/models"
    "gorm.io/gorm"

    "github.com/gin-gonic/gin"
    "golang.org/x/oauth2"
    "golang.org/x/oauth2/github"
)

var (
    githubOauthConfig = &oauth2.Config{
        RedirectURL:  "http://195.35.29.110:8080/auth/github/callback",
        ClientID:     os.Getenv("CLIENT_ID_GITHUB_AUTH"),
        ClientSecret: os.Getenv("CLIENT_SECRET_GITHUB_AUTH"),
        Scopes:       []string{"user:email"},
        Endpoint:     github.Endpoint,
    }
)

func OAuthCallbackHandler(provider string) gin.HandlerFunc {
    return func(c *gin.Context) {
        accessToken := c.Query("token")
        log.Printf("Access Token: %v", accessToken)

        token := &oauth2.Token{
            AccessToken: accessToken,
            TokenType:   "Bearer",
            Expiry:      time.Now().Add(time.Hour),
        }

        client := githubOauthConfig.Client(context.Background(), token)
        userEmail, err := fetchUserEmail(client)
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to fetch GitHub user email"})
            return
        }

        var user models.User
        result := db.GetDB().Where("email = ?", userEmail).First(&user)
        if result.Error != nil && !errors.Is(result.Error, gorm.ErrRecordNotFound) {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
            return
        }

        if result.RowsAffected == 0 {
            githubUser, err := fetchGitHubUserProfile(client)
            if err != nil {
                c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to fetch GitHub user profile"})
                return
            }

            user = models.User{
                Email:    userEmail,
                Pseudo:   githubUser.Pseudo,
                Provider: "github",
                IsVerified: true,
            }
            if err := db.GetDB().Create(&user).Error; err != nil {
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
                return
            }
        }

        tokenString, err := controllers.GenerateJWT(user.ID, user.Email, user.Role)
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate JWT"})
            return
        }

        c.JSON(http.StatusOK, gin.H{"token": tokenString})
    }
}

func fetchUserEmail(client *http.Client) (string, error) {
    req, _ := http.NewRequest("GET", "https://api.github.com/user/emails", nil)
    req.Header.Add("Accept", "application/json")
    resp, err := client.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return "", err
    }

    var emails []struct {
        Email      string `json:"email"`
        Primary    bool   `json:"primary"`
        Verified   bool   `json:"verified"`
    }
    if err := json.Unmarshal(body, &emails); err != nil {
        return "", err
    }

    for _, email := range emails {
        if email.Primary && email.Verified {
            return email.Email, nil
        }
    }
    return "", fmt.Errorf("no verified primary email found")
}

func fetchGitHubUserProfile(client *http.Client) (models.User, error) {
    req, _ := http.NewRequest("GET", "https://api.github.com/user", nil)
    req.Header.Add("Accept", "application/json")
    resp, err := client.Do(req)
    if err != nil {
        return models.User{}, err
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        return models.User{}, err
    }

    var userProfile struct {
        Login string `json:"login"`
    }
    if err := json.Unmarshal(body, &userProfile); err != nil {
        return models.User{}, err
    }

    return models.User{Pseudo: userProfile.Login}, nil
}
