package services

import (
	"golang.org/x/oauth2/google"
    "golang.org/x/oauth2"
    "golang.org/x/oauth2/github"
	"github.com/gin-gonic/gin"
	"net/http"
	"context"
	"os"
)

var (
	googleOauthConfig = &oauth2.Config{
        RedirectURL:  "http://195.35.29.110:8080/auth/google/callback",
        ClientID:     "your-google-client-id",
        ClientSecret: "your-google-client-secret",
        Scopes:       []string{"https://www.googleapis.com/auth/userinfo.email"},
        Endpoint:     google.Endpoint,
    }

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
        code := c.Query("code")
        var token *oauth2.Token
        var err error

        switch provider {
        case "google":
            token, err = googleOauthConfig.Exchange(context.Background(), code)
        case "github":
            token, err = githubOauthConfig.Exchange(context.Background(), code)
        }

        if err != nil {
            c.AbortWithError(http.StatusBadRequest, err)
            return
        }

        c.JSON(http.StatusOK, gin.H{"status": "Vous êtes connecté avec " + provider, "token_expires_in": token.Expiry})
    }
}