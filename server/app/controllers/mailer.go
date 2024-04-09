package controllers


import (
    "net/smtp"
	"log"
    "os"
)

var (
	smtpHost = os.Getenv("SMTP_HOST")
	smtpPort = os.Getenv("SMTP_PORT")
	smtpUser = os.Getenv("SMTP_USER")
	smtpPass = os.Getenv("SMTP_PASSWORD")
)

func SendEmail(to, subject, body string) {
    go func() {
        err := sender(to, subject, body)
        if err != nil {
            log.Printf("Erreur lors de l'envoi de l'email: %v", err)
        }
    }()
}

func sender(to, subject, body string) error {
    from := smtpUser
    msg := "From: " + from + "\r\n" +
        "To: " + to + "\r\n" +
        "Subject: " + subject + "\r\n\r\n" +
        body

    auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
    addr := smtpHost + ":" + smtpPort

    return smtp.SendMail(addr, auth, from, []string{to}, []byte(msg))
}
