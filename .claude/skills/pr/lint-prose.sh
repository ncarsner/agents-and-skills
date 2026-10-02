#!/usr/bin/env bash
# Lint version control prose for the /pr skill.
#
#   lint-prose.sh spelling FILE...   British spellings, one hit per line
#   lint-prose.sh body FILE          spelling + register + layout for a PR or issue body
#
# Prints nothing and exits 0 when clean. Hits are for review: identifiers,
# quoted external text, and detection patterns are legitimate.
set -u

BRITISH='[a-z]*(organis|recognis|realis|normalis|initialis|serialis|deserialis|optimis|prioritis|summaris|customis|authoris|categoris|standardis|utilis|minimis|maximis|finalis|synchronis|visualis|specialis|characteris|memoris|parametris|tokenis|sanitis|randomis|containeris|virtualis|apologis|emphasis)(e|ed|es|er|ers|ing|ation|ations)|(analys|paralys)(e|ed|er|ers|ing)|[a-z]*(colour|behaviour|favour|honour|labour|flavour|neighbour|humour|armour|harbour)[a-z]*|(centre|metre|litre|fibre|theatre)s?|(cancel|label|model|travel|signal|fuel|level|total)l(ed|ing)|catalogue[sd]?|licence[sd]?|defence|offence|grey|whilst|amongst|judgement|artefacts?|fulfil(s|ment)?|enrol(s|ment)?'

REGISTER='(the user|user (asked|wanted|requested)|as requested|you asked|we (discussed|decided|agreed|talked)|in this (session|conversation|chat)|let me|^I |[^[:alnum:]]I (added|changed|fixed|updated|made|ran|think)|I'"'"'(ve|m|ll))'

spelling() { grep -nowiE "$BRITISH" "$@"; }

register() { grep -nE "$REGISTER" "$1"; }

layout() {
	awk '
	function item(s) { return s ~ /^[[:space:]]*([-*+]|[0-9]+\.) / }
	/^```/ { fence = !fence; last = ""; blank = 0; next }
	fence { next }
	$0 == "" {
		if (NR == 1 || blank) print NR ": leading or doubled blank line"
		blank = 1; next
	}
	{
		if (blank && item($0) && item(last)) print NR ": blank line inside a list"
		if (!blank && last != "" && last !~ /^#/ && $0 !~ /^[[:space:]]*([-*+>|#]|[0-9]+\. )/)
			print NR ": hard-wrapped line (join it to the line above)"
		last = $0; blank = 0
	}
	END { if (blank) print "trailing blank line" }
	' "$1"
}

case "${1:-}" in
spelling)
	shift
	out=$(spelling "$@")
	;;
body)
	out=$({ spelling "$2" | sed 's/^/spelling: /'; register "$2" | sed 's/^/register: /'; layout "$2" | sed 's/^/layout: /'; })
	;;
*)
	echo "usage: lint-prose.sh spelling FILE... | lint-prose.sh body FILE" >&2
	exit 2
	;;
esac

[ -z "$out" ] && exit 0
printf '%s\n' "$out"
exit 1
