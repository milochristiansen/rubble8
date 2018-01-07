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

import "fmt"
import "strconv"
import "errors"

// ParseRules parses a rule file into the given tree.
// For a new tree simply pass a pointer to an empty RuleNode.
func ParseRules(file []byte, tree *RuleNode) (err error) {
	lex := newLexer(file)
	blocks := map[string]*RuleNode{}
	trees := []*RuleNode{tree}

	err = nil
	defer func(err *error) {
		if x := recover(); x != nil {
			*err = errors.New("Invalid syntax found while parsing rule file at: " + x.(string))
		}
	}(&err)

	for !lex.checkLookAhead(tknINVALID) {
		parseRuleSet(lex, trees, blocks)
	}
	return err
}

// Parse a sequence of rules.
func parseRuleSet(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	// Parse one rule
	branches := parseRule(lex, trees, blocks)
	if lex.checkLookAhead(tknRuleSplit) {
		lex.getToken(tknRuleSplit)
		return parseRuleSet(lex, branches, blocks)
	}
	return branches
}

// Parse a single rule
func parseRule(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	switch lex.look.Type {
	case tknBlockOpen:
		return parseBlockRule(lex, trees, blocks)
	case tknInsert:
		return parseInsertRule(lex, trees, blocks)
	case tknDeclare:
		return parseDeclareRule(lex, trees, blocks)
	case tknWCMatch, tknWCMerge, tknWCDiscard, tknItem:
		return parseMatchRule(lex, trees, blocks)
	default:
		panic(fmt.Sprint("Line: ", lex.look.Line))
	}
}

func parseBlockRule(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	lex.getToken(tknBlockOpen)
	branches := make([]*RuleNode, 0)
	for !lex.checkLookAhead(tknBlockClose) {
		branches = append(branches, parseRuleSet(lex, trees, blocks)...)
	}
	lex.getToken(tknBlockClose)
	return branches
}

func parseInsertRule(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	lex.getToken(tknInsert)
	lex.getToken(tknArgOpen)
	lex.getToken(tknItem)
	name := lex.current.Lexeme
	lex.getToken(tknArgClose)

	branches := make([]*RuleNode, 0)
	if block, ok := blocks[name]; ok {
		for _, tree := range trees {
			nnodes := block.dup(nil)
			for i := range nnodes.Rules {
				nnodes.Children[i].Parent = tree
				tree.addExistingRule(nnodes.Rules[i], nnodes.Children[i])
				branches = append(branches, nnodes.Children[i])
			}
		}
	}
	return branches
}

func parseDeclareRule(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	lex.getToken(tknDeclare)
	lex.getToken(tknArgOpen)
	lex.getToken(tknItem)
	name := lex.current.Lexeme
	lex.getToken(tknArgClose)

	rules := []*RuleNode{new(RuleNode)}
	parseRuleSet(lex, rules, blocks)
	blocks[name] = rules[0]
	return trees
}

func parseMatchRule(lex *lexer, trees []*RuleNode, blocks map[string]*RuleNode) []*RuleNode {
	rules := []Rule{}

	for !lex.checkLookAhead(tknRuleSplit) {
		switch lex.look.Type {
		case tknWCMatch:
			lex.getToken(tknWCMatch)
			min, max := readRange(lex)
			rules = append(rules, Rule{
				Mode: RuleKey,
				Min:  min,
				Max:  max,
			})
		case tknWCMerge:
			lex.getToken(tknWCMerge)
			min, max := readRange(lex)
			rules = append(rules, Rule{
				Mode: RuleMerge,
				Min:  min,
				Max:  max,
			})
		case tknWCDiscard:
			lex.getToken(tknWCDiscard)
			min, max := readRange(lex)
			rules = append(rules, Rule{
				Mode: RuleDiscard,
				Min:  min,
				Max:  max,
			})
		case tknItem:
			lex.getToken(tknItem)
			rules = append(rules, Rule{
				Items: []string{lex.current.Lexeme},
				Min:  1,
				Max:  1,
			})
		case tknBlockOpen:
			lex.getToken(tknBlockOpen)
			items := []string{}
			for !lex.checkLookAhead(tknBlockClose) {
				lex.getToken(tknItem)
				items = append(items, lex.current.Lexeme)
			}
			rules = append(rules, Rule{
				Items: items,
				Min:  1,
				Max:  1,
			})
			lex.getToken(tknBlockClose)
		default:
			panic(fmt.Sprint("Line: ", lex.look.Line))
		}
		if lex.checkLookAhead(tknTagSplit) {
			lex.getToken(tknTagSplit)
			continue
		}
		break
	}

	branches := make([]*RuleNode, 0)
	for _, tree := range trees {
		_, branch := tree.addRule(rules)
		branches = append(branches, branch)
	}
	return branches
}

func readRange(lex *lexer) (int, int) {
	if !lex.checkLookAhead(tknArgOpen) {
		return 1, 1
	}

	lex.getToken(tknArgOpen)
	lex.getToken(tknItem)
	min, err := strconv.Atoi(lex.current.Lexeme)
	if err != nil {
		panic(fmt.Sprint("Line: ", lex.current.Line))
	}

	max := min
	if lex.checkLookAhead(tknArgSep) {
		lex.getToken(tknArgSep)
		if lex.checkLookAhead(tknItem) {
			lex.getToken(tknItem)
			max, err = strconv.Atoi(lex.current.Lexeme)
			if err != nil {
				panic(fmt.Sprint("Line: ", lex.current.Line))
			}
		} else {
			max = -1
		}
	}
	lex.getToken(tknArgClose)

	if max < min && max >= 0 {
		max = min
	}
	return min, max
}
