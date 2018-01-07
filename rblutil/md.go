/*
Copyright 2013-2018 by Milo Christiansen

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
that you wrote the original software. If you use this software in a product, an
acknowledgment in the product documentation would be appreciated but is not
required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
*/

package rblutil

import "html/template"
import "net/url"
import "strings"
import "regexp"
import "bytes"

import "github.com/knieriem/markdown"

var addonNameFind = regexp.MustCompile("`addon:[^`\n\r]+`")
var addonNameIsolate = regexp.MustCompile("^`addon:([^`\n\r]+)`$")

// MarkdownToHTML parses markdown text and returns the HTML result.
func MarkdownToHTML(src string) template.HTML {
	p := markdown.NewParser(&markdown.Extensions{Smart: true})
	buf := new(bytes.Buffer)

	// Custom extension #1
	// `addon:Test/Some Addon`
	// [`Test/Some Addon`](/addondata?addon=Test/Some+Addon)
	src = addonNameFind.ReplaceAllStringFunc(src, func(match string) string {
		matches := addonNameIsolate.FindStringSubmatch(match)
		// If we didn't need to escape the query this would be simpler and faster.
		return "[`" + matches[1] + "`](/addondata?addon=" + url.QueryEscape(matches[1]) + ")"
	})

	p.Markdown(strings.NewReader(src), markdown.ToHTML(buf))
	return template.HTML(buf.String())
}

// MarkdownLineToHTML is exactly like MarkdownToHTML except it forcibly ensures the output is a single line with no
// <br> or <p> tags.
func MarkdownLineToHTML(src string) template.HTML {
	line := string(MarkdownToHTML(src))

	// Fix some stupid issues with header lines.
	// They should not have any line breaks, including <p> tags.
	line = strings.Replace(line, "\n", "", -1)
	line = strings.Replace(line, "\r", "", -1)
	line = strings.Replace(line, "<p>", "", -1)
	line = strings.Replace(line, "</p>", "", -1)
	line = strings.Replace(line, "<br>", "", -1)

	return template.HTML(line)
}
