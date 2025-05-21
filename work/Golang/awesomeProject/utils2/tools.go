package utils2

import (
	"slices"
)

func removeElement(input []string, e string) []string {

	if slices.Contains(input, e) {
		i := slices.Index(input, e)
		return removeElement(slices.Delete(input, i, i+1), e)
	}
	return input
}
