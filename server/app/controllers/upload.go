package controllers

import (
	"errors"
	"mime/multipart"
)

const MaxUploadSize = 10 << 20

var AllowedExtensions = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/jpg":  true,
}

func ValidateFileUpload(fileHeader *multipart.FileHeader) error {
	if fileHeader.Size > MaxUploadSize {
		return errors.New("le fichier est trop volumineux")
	}

	if _, allowed := AllowedExtensions[fileHeader.Header.Get("Content-Type")]; !allowed {
		return errors.New("type de fichier non autorisé")
	}

	return nil
}
