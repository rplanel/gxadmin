query_tbl() {
	psql <<-EOF
	$1
	EOF
}

query_tsv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER E'\t'
	EOF
}

query_csv() {
	psql <<-EOF
	COPY ($1) to STDOUT with CSV DELIMITER ','
	EOF
}

query_exp() {
	psql <<-EOF
	EXPLAIN ANALYZE VERBOSE $1
	EOF
}

query_expj() {
	echo "$1"
	echo
	psql -qAt <<-EOF
	EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) $1
	EOF
}

query_influx() {
	local query="$1"
	local rename="$2"
	local fields="$3"
	local tags="$4"
	local timestamp="$5"

	if [[ -z "$fields" ]]; then
		exit 0;
	fi

	arr2py=$(cat <<EOF
import sys
query_name = sys.argv[1]
fields = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[2].split(';')}
tags = []
if len(sys.argv) > 3 and len(sys.argv[3]) > 0:
	tags = {x.split('=')[0]: int(x.split('=')[1]) for x in sys.argv[3].split(';')}

timestamp = None
if len(sys.argv) > 4 and sys.argv[4] != '':
	timestamp = int(sys.argv[4])

for line in sys.stdin.read().split('\n'):
	if len(line) == 0:
		continue
	parsed = line.split('\t')
	metric = query_name
	if len(tags):
		tag_data = ['%s=%s' % (k, parsed[v].replace(' ', '\\ ').replace(',', '\\,').replace('=', '\\='))  for (k, v) in tags.items()]
		metric += ',' + ','.join(tag_data)
	field_data = ['%s=%s' % (k, parsed[v])  for (k, v) in fields.items()]
	metric += ' ' + ','.join(field_data)

	if timestamp is not None:
		metric += ' ' + str(parsed[timestamp])
	print(metric)
EOF
)

	psql -c "COPY ($query) to STDOUT with CSV DELIMITER E'\t'"| python -c "$arr2py" "$rename" "$fields" "$tags" "$timestamp"
}

gdpr_safe() {
	local coalesce_to
	if (( $# > 2 )); then
		coalesce_to="$3"
	else
		coalesce_to="__UNKNOWN__"
	fi

	if [ -z "$GDPR_MODE"  ]; then
		echo "COALESCE($1, '$coalesce_to')"
	else
		# Try and be privacy respecting while generating numbers that can allow
		# linking data across tables if need be?
		echo "substring(md5(COALESCE($1, '$coalesce_to') || now()::date), 0, 12) as ${2:-$1}"
	fi
}

# Borrowed from https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function join_by {
	local d=$1; shift;
	echo -n "$1";
	shift;
	printf "%s" "${@/#/$d}";
}
