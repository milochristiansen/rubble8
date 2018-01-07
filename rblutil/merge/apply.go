/*
Copyright 2014-2016 by Milo Christiansen

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

// This package provides a powerful match/merge engine for working with raw files.
// 
// This engine uses a rule-based matcher that allows tags to be matched to rules or
// tags to rules and each other. When matching two sets of tags together it is possible
// to merge parts of the one set into the other (based on the provided rules of course).
package merge

import "rubble8/rblutil/rparse"
import "fmt"

// Apply modifies the tags in file with information from the tree.
func Apply(tags []*rparse.Tag, tree *TagNode) {
	node := tree
	
nexttag:
	for _, tag := range tags {
		if tag.CommentsOnly {
			continue
		}
		
		// Try to get a match from the current node's children
		nnode, ni := node.Match(tag)
		if nnode != nil {
			node.MergeInto(tag, ni)
			node = nnode
			continue
		}
		
		// No match, scan up the tree to see if it is a higher level tag.
		n := node
		for n.Parent != nil {
			n = n.Parent
			nnode, ni = n.Match(tag)
			if nnode != nil {
				n.MergeInto(tag, ni)
				node = nnode
				continue nexttag
			}
		}
		
		// Relevel the tree.
		// This prevents lower level tags belonging to unmatched upper level tags from appearing to
		// be attached to the last matched upper level tag
		if node.MatchRule(tag) {
			continue
		}
		n = node
		for n.Parent != nil {
			n = n.Parent
			if n.MatchRule(tag) {
				node = n
				continue nexttag
			}
		}
		
		// If the tag still matches nothing then ignore it.
	}
}

// Match takes a parsed raw file and matches it against a set of merge rules.
// Returns a slice of error messages for the logger.
func Match(tags []*rparse.Tag, rules *RuleNode) []string {
	node := rules

	missing := []string{}

nexttag:
	for _, t := range tags {
		if t.CommentsOnly {
			continue
		}
		t.Comments = "" // Zap the comments to prevent messy error messages.
		
		// Try to get a match from the current rule's children
		nnode, _ := node.Match(t)
		if nnode != nil {
			node = nnode
			continue
		}
		
		// No match, scan up the tree to see if it is a higher level tag.
		n := node
		for n.Parent != nil {
			n = n.Parent
			nnode, _ = n.Match(t)
			if nnode != nil {
				node = nnode
				continue nexttag
			}
		}
		
		missing = append(missing, fmt.Sprintf("\"%v\" (line: %v).", t, t.Line))
		
		// When working with rules there is no need to manually relevel the tree on match failure.
	}
	return missing
}
