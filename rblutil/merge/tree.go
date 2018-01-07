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

package merge

import "rubble8/rblutil/rparse"

// TagTree is a node in a tree that represents the relations tags have to each
// other as defined by the rules used to create the tree.
type TagTree struct {
	Me       *rparse.Tag
	Parent   *TagTree
	Children []*TagTree
}

// String does a very simple print of a tree as rooted at this node.
// This is only suitable for debugging.
func (tt *TagTree) String() string {
	return tt.str("")
}

func (tt *TagTree) str(prefix string) string {
	out := ""
	if tt.Me != nil {
		out = prefix+tt.Me.String()+"\n"
	}
	
	for _, child := range tt.Children {
		out += child.str(prefix+"\t")
	}
	return out
}

func addToTree(parent *TagTree, tag *rparse.Tag) *TagTree {
	ntn := &TagTree{
		Me: tag,
		Parent: parent,
	}
	parent.Children = append(parent.Children, ntn)
	return ntn
}

// TreeifyRaws takes a set of raws and turns them into a tree based on the given rules.
// This is basically a super mode for the raw parser, allowing easy editing of certain
// kinds of objects (with the proper rules).
func TreeifyRaws(tags []*rparse.Tag, rules *RuleNode) *TagTree {
	node := rules

	roottag := new(TagTree)
	tagnode := roottag
	
nexttag:
	for _, t := range tags {
		if t.CommentsOnly {
			continue
		}
		t.Comments = "" // Zap the comments to keep things neat.
		
		// Try to get a match from the current rule's children
		nnode, _ := node.Match(t)
		if nnode != nil {
			node = nnode
			tagnode = addToTree(tagnode, t)
			continue
		}
		
		// No match, scan up the tree to see if it is a higher level tag.
		n := node
		tn := tagnode
		for n.Parent != nil {
			n = n.Parent
			tn = tn.Parent
			nnode, _ = n.Match(t)
			if nnode != nil {
				node = nnode
				tagnode = addToTree(tn, t)
				continue nexttag
			}
		}
		
		// Ignore any unmatched tags
	}
	return roottag
}
