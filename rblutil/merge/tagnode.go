/*
Copyright 2014-2018 by Milo Christiansen

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

import "github.com/milochristiansen/rubble8/rblutil/rparse"

// TagNode is a group of raw tags matched to rules to be used in constructing a raw tree.
type TagNode struct {
	Tags     []*rparse.Tag
	Rules    [][]Rule
	Children []*TagNode
	Parent   *TagNode
}

func (node *TagNode) strHelper(prefix string) string {
	out := ""
	for i, tag := range node.Tags {
		com := tag.Comments
		tag.Comments = ""
		if prefix == "" {
			out += "\n" + tag.String() + "\n"
		} else {
			out += prefix + tag.String() + "\n"
		}
		tag.Comments = com
		out += node.Children[i].strHelper(prefix + "\t")
	}
	return out
}

// String prints a raw tree as a set of properly indented raw tags.
func (node *TagNode) String() string {
	return node.strHelper("")
}

// Match attempts to find a tag that matches the given one in this node, returning
// the node and the index if found. If not found nil and 0 are returned.
func (node *TagNode) Match(tag *rparse.Tag) (*TagNode, int) {
	elements := makeElements(tag)

	for i := range node.Children {
		if len(node.Tags[i].Params) == len(tag.Params) {
			if matchAndMerge(elements, makeElements(node.Tags[i]), node.Rules[i], false) {
				return node.Children[i], i
			}
		}
	}
	return nil, 0
}

// Match attempts to find a rule that matches the given tag in this node, returning
// true if found. This ignores the tags attached to the rules.
func (node *TagNode) MatchRule(tag *rparse.Tag) bool {
	elements := makeElements(tag)

	for i := range node.Children {
		if matchAndMerge(elements, nil, node.Rules[i], false) {
			return true
		}
	}
	return false
}

// MergeInto merges the tag at the given index in the node into the given raw tag.
func (node *TagNode) MergeInto(tag *rparse.Tag, idx int) {
	elements := makeElements(node.Tags[idx])
	result := makeElements(tag)

	matchAndMerge(elements, result, node.Rules[idx], true)
	tag.ID = result[0]
	for i := range tag.Params {
		tag.Params[i] = result[i+1]
	}
}

func (node *TagNode) hasMergeRule(idx int) bool {
	for _, rule := range node.Rules[idx] {
		if rule.Mode == RuleMerge {
			return true
		}
	}
	return false
}

func (node *TagNode) removeTag(idx int) {
	node.Tags = append(node.Tags[:idx], node.Tags[idx+1:]...)
	node.Rules = append(node.Rules[:idx], node.Rules[idx+1:]...)
	node.Children = append(node.Children[:idx], node.Children[idx+1:]...)
}

func (node *TagNode) addTag(tag *rparse.Tag, rule []Rule) *TagNode {
	// First see if we already have this tag.
	nnode, ni := node.Match(tag)
	if nnode != nil {
		// If so replace the existing tag with the new one (without changing it's children).
		node.Tags[ni] = tag
		return node.Children[ni]
	}

	// If we don't then create a new tag.
	nnode = new(TagNode)
	nnode.Parent = node

	node.Tags = append(node.Tags, tag)
	node.Rules = append(node.Rules, rule)
	node.Children = append(node.Children, nnode)
	return nnode
}

func makeElements(tag *rparse.Tag) []string {
	elements := make([]string, 1, len(tag.Params)+1)
	elements[0] = tag.ID
	return append(elements, tag.Params...)
}

// MakeTree makes a tree from a raw file (generally the output from Flatten).
// The tree is pruned to the minimum set of merge-able tags. This means not
// only are tags that are not in the rules discarded, but so are tags
// that do not have merge rules or children with merge rules.
func MakeTree(tags []*rparse.Tag, rtree *RuleNode) *TagNode {
	tree := new(TagNode)
	PopulateTree(tags, tree, rtree)
	return tree
}

// PopulateTree is the same as MakeTree, but for a preexisting tree.
func PopulateTree(tags []*rparse.Tag, tree *TagNode, rtree *RuleNode) {
	rnode := rtree
	node := tree
	for _, tag := range tags {
		nrnode, ri := rnode.Match(tag)
		if nrnode != nil {
			rnode = nrnode
			node = node.addTag(tag, nrnode.Parent.Rules[ri])
		} else {
			rn := rnode
			n := node
			for rn.Parent != nil {
				rn = rn.Parent
				n = n.Parent
				nrnode, ri = rn.Match(tag)
				if nrnode != nil {
					rnode = nrnode
					node = n.addTag(tag, nrnode.Parent.Rules[ri])
					break
				}
			}
		}
	}

	pruneTree(tree, -1)
}

func pruneTree(tree *TagNode, idx int) bool {
	// First prune all children then
	prune := []int{}
	for i, child := range tree.Children {
		if pruneTree(child, i) {
			prune = append(prune, i)
		}
	}
	for i := len(prune) - 1; i >= 0; i-- {
		tree.removeTag(prune[i])
	}

	// if we have no merge rules and no children prune this node (or rather tell our caller to prune this node).
	if len(tree.Children) == 0 && tree.Parent != nil {
		return !tree.Parent.hasMergeRule(idx)
	}
	return false
}
