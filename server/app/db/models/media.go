package models

import (
	"gorm.io/gorm"
)

type Media struct {
	gorm.Model
	FileName  string
	MimeType  string
	URL       string
}
