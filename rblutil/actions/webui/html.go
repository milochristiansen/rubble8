/*
Copyright 2013-2018 by Milo Christiansen

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented you must not claim
that you wrote the original software. If you use this software in a product, an
acknowledgment in the product documentation would be appreciated but is not
required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.
*/

package webui

import "html/template"
import "github.com/milochristiansen/rubble8/rblutil"
import "github.com/milochristiansen/axis2"

func LoadHTMLTemplates(fs *axis2.FileSystem) (*template.Template, error) {
	tmpl := template.New("webUI")

	// Main Menu and Common Pages

	_, err := rblutil.LoadTemplate(fs, tmpl, "menu", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "pleasewait", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "kill", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "log", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "doclist", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "docpage", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "addondata", ".html")
	if err != nil {
		return nil, err
	}

	// Master Addon List

	_, err = rblutil.LoadTemplate(fs, tmpl, "addons", ".html")
	if err != nil {
		return nil, err
	}

	// Normal Generation

	_, err = rblutil.LoadTemplate(fs, tmpl, "genaddons", ".html")
	if err != nil {
		return nil, err
	}

	// Tilesets and Independent Apply

	_, err = rblutil.LoadTemplate(fs, tmpl, "iaaddons", ".html")
	if err != nil {
		return nil, err
	}

	_, err = rblutil.LoadTemplate(fs, tmpl, "srvrpacks", ".html")
	if err != nil {
		return nil, err
	}

	return tmpl, nil
}
