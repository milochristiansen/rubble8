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

import "strconv"
import "github.com/milochristiansen/rubble8/rblutil/rparse"

// Values for Rule.Mode
const (
	RuleMatch = iota
	RuleDiscard
	RuleKey
	RuleMerge
)

// Rule is a rule for matching one or more elements, several of these are chained
// together to match a whole raw tag.
// A Rule should **never** be changed after it is created.
type Rule struct {
	Mode  int
	Items []string
	Min   int
	Max   int
}

func (rule Rule) eq(b Rule) bool {
	if rule.Mode != b.Mode || rule.Min != b.Min || rule.Max != b.Max || len(rule.Items) != len(b.Items) {
		return false
	}

	for i := range rule.Items {
		if rule.Items[i] != b.Items[i] {
			return false
		}
	}
	return true
}

// String formats a Rule to the text form of the rule.
func (rule *Rule) String() string {
	return rule.strHelper("")
}

// String formats a Rule to the text form of the rule.
func (rule *Rule) strHelper(prefix string) string {
	switch rule.Mode {
	case RuleDiscard:
		if rule.Min == 1 && rule.Max == 1 {
			return "&"
		}
		if rule.Min == rule.Max {
			return "&(" + strconv.Itoa(rule.Min) + ")"
		}
		return "&(" + strconv.Itoa(rule.Min) + "," + strconv.Itoa(rule.Max) + ")"
	case RuleKey:
		if rule.Min == 1 && rule.Max == 1 {
			return "$"
		}
		if rule.Min == rule.Max {
			return "$(" + strconv.Itoa(rule.Min) + ")"
		}
		return "$(" + strconv.Itoa(rule.Min) + "," + strconv.Itoa(rule.Max) + ")"
	case RuleMerge:
		if rule.Min == 1 && rule.Max == 1 {
			return "?"
		}
		if rule.Min == rule.Max {
			return "?(" + strconv.Itoa(rule.Min) + ")"
		}
		return "?(" + strconv.Itoa(rule.Min) + "," + strconv.Itoa(rule.Max) + ")"
	default:
		out := "{"
		for _, item := range rule.Items {
			out += "\n\t" + prefix + item
		}
		return out + "\n}"
	}
}

func formatRule(rules []Rule, prefix string) string {
	out := ""
	for _, rule := range rules {
		out += rule.strHelper(prefix) + ":"
	}

	if len(out) > 0 {
		return out[:len(out)-1]
	}
	return out
}

// RuleNode is a set of rules that are attached to child RuleNodes.
// Values of this type are used to form a tree.
type RuleNode struct {
	Rules    [][]Rule
	Children []*RuleNode
	Parent   *RuleNode
}

func (node *RuleNode) addRule(rules []Rule) (int, *RuleNode) {
	// Do nothing if the rule already exists.
nextrule:
	for r := range node.Rules {
		if len(node.Rules[r]) != len(rules) {
			continue
		}
		for i := 0; i < len(rules); i++ {
			if !node.Rules[r][i].eq(rules[i]) {
				continue nextrule
			}
		}
		return r, node.Children[r]
	}

	// Otherwise add the rule as a new node.
	child := new(RuleNode)
	child.Parent = node

	node.Rules = append(node.Rules, rules)
	node.Children = append(node.Children, child)
	return len(node.Rules) - 1, child
}

func (node *RuleNode) addExistingRule(rules []Rule, child *RuleNode) int {
	// Merge the nodes if a node with that rule already exists.
nextrule:
	for r := range node.Rules {
		if len(node.Rules[r]) != len(rules) {
			continue
		}
		for i := 0; i < len(rules); i++ {
			if !node.Rules[r][i].eq(rules[i]) {
				continue nextrule
			}
		}

		node.Children[r].Rules = append(node.Children[r].Rules, child.Rules...)
		node.Children[r].Children = append(node.Children[r].Children, child.Children...)
		return r
	}

	// Otherwise add the node.
	node.Rules = append(node.Rules, rules)
	node.Children = append(node.Children, child)
	return len(node.Rules) - 1
}

func (node *RuleNode) dup(parent *RuleNode) *RuleNode {
	nnode := new(RuleNode)
	nnode.Parent = parent
	nnode.Rules = make([][]Rule, len(node.Rules))
	copy(nnode.Rules, node.Rules)
	nnode.Children = make([]*RuleNode, len(node.Children))
	for i, child := range node.Children {
		nnode.Children[i] = child.dup(nnode)
	}
	return nnode
}

func (node *RuleNode) bammHelper(prefix string) string {
	if len(node.Children) == 0 {
		return prefix + "\n"
	}
	out := ""
	for i, rule := range node.Rules {
		if prefix == "" {
			out += node.Children[i].bammHelper(formatRule(rule, prefix))
		} else {
			out += node.Children[i].bammHelper(prefix + "|" + formatRule(rule, prefix))
		}
	}
	return out
}

// ExportBAMMCompat returns the string form of all the rules making up the tree as rooted from the given RuleNode in a
// mostly BAMM compatible "flat" format (no rule blocks).
// Range statements will still use the Rubble extensions!
func (node *RuleNode) ExportBAMMCompat() string {
	return node.bammHelper("")
}

func (node *RuleNode) strHelper(prefix string) string {
	if len(node.Children) == 1 {
		if len(node.Children[0].Children) > 0 {
			return formatRule(node.Rules[0], prefix) + "|" + node.Children[0].strHelper(prefix)
		}
		return formatRule(node.Rules[0], prefix) + "\n"
	}

	out := "{"
	prefix += "\t"
	for i := range node.Children {
		if len(node.Children[i].Children) > 0 {
			out += prefix + formatRule(node.Rules[i], prefix) + "|" + node.Children[i].strHelper(prefix)
		}
		out += prefix + formatRule(node.Rules[i], prefix) + "\n"
	}
	return out + "}"
}

// String returns the string form of all the rules making up the tree as rooted from the given RuleNode.
// This function tries to use blocks where possible, but any named rules and such will be inlined.
func (node *RuleNode) String() string {
	if len(node.Children) == 0 {
		return ""
	}

	return node.strHelper("")
}

// matchAndMerge allows you to match tags to rules and merge tags according to rules.
// elements is the first tag, target the second. To match a single tag to a rule
// set target to nil. To match two tags to a a rule and each other set both.
// To merge tags set the tag you want to merge into as target and set merge to true.
func matchAndMerge(elements, target []string, rules []Rule, merge bool) bool {
	// Make sure the merge/match candidates are the same length.
	if target != nil {
		if len(target) != len(elements) {
			return false
		}
	}

	// Make sure the tag element count matches that required by the rule.
	min, max := 0, 0
	for _, rule := range rules {
		min += rule.Min
		if rule.Max < 0 {
			max += 500
		} else {
			max += rule.Max
		}
	}
	if min > len(elements) || max < len(elements) {
		return false
	}

	// Match each element against the current rule.
	e, ok := 0, true
loop:
	for r, rule := range rules {
		// Check the first few items (up to rule.Min)
		if e+rule.Min > len(elements) {
			// Too few items to satisfy rule.
			ok = false
			break loop
		}
		for i := e; i < e+rule.Min; i++ {
			switch rule.Mode {
			case RuleMatch:
				ok = false
				for _, item := range rule.Items {
					if item == elements[i] && (target == nil || target[i] == elements[i]) {
						ok = true
						break
					}
				}
				if !ok {
					// No match
					break loop
				}
			case RuleDiscard:
				// Do nothing
			case RuleKey:
				if target != nil && target[i] != elements[i] {
					// No match
					ok = false
					break loop
				}
			case RuleMerge:
				if merge && target != nil {
					target[i] = elements[i]
				}
			}
		}
		e += rule.Min

		// If Min == Max then go on to the next rule.
		if rule.Min == rule.Max {
			continue loop
		}

		// Check the remaining items

		padding := rule.Max - rule.Min
		if rule.Max < 0 {
			padding = 500
		}

		// Scan ahead to find the next hard match

		// Is this the last rule? If so we need to make sure all items are consumed.
		scanToEnd := true
		nextRule := rule
		if r < len(rules)-1 {
			nextRule = rules[r+1]
			scanToEnd = false
		}
		if !scanToEnd && nextRule.Mode != RuleMatch {
			// Malformed rule.
			ok = false
			break loop
		}

		te := e
	wc:
		for i := 0; i < padding; i++ {
			if e+i >= len(elements) {
				if !scanToEnd {
					// Too few items to satisfy rule.
					ok = false
				}
				break loop
			}

			if !scanToEnd {
				for _, item := range nextRule.Items {
					if item == elements[e+i] {
						break wc
					}
				}
			}

			switch rule.Mode {
			case RuleMatch:
				panic("IMPOSSIBLE!") // RuleMatch rules are always Min == Max == 1
			case RuleDiscard:
				// Do nothing
			case RuleKey:
				if target != nil && target[e+i] != elements[e+i] {
					// No match
					ok = false
					break loop
				}
			case RuleMerge:
				if merge && target != nil {
					target[e+i] = elements[e+i]
				}
			}
			te++
		}
		e = te

		if scanToEnd {
			// We should be at the end, make sure
			if e != len(elements) {
				ok = false
				break loop
			}
			continue loop
		}
		// Make sure there are items for the next rule.
		if e >= len(elements) {
			ok = false
			break loop
		}
	}
	return ok
}

// Match checks to see if the given node contains a child that matches the given raw tag,
// if so that child and the child's index are returned. If the tag matches no rules nil
// and 0 are returned.
func (node *RuleNode) Match(tag *rparse.Tag) (*RuleNode, int) {
	elements := makeElements(tag)

	for r, rules := range node.Rules {
		if matchAndMerge(elements, nil, rules, false) {
			return node.Children[r], r
		}
	}
	return nil, 0
}
