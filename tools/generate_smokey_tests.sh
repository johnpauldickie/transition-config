#!/bin/sh

#
#  generate cucumber smoke tests from sites.csv
#
cmd=$(basename $0)
sites="data/sites.csv"
today=$(date +"%Y%m%d")
verbose=""

usage() {
    echo "usage: $cmd [opts] [mappings.csv ...]" >&2
    echo "    [-s|--sites $sites] sites file" >&2
    echo "    [-t|--today YYYYMMDD]       today's date" >&2
    echo "    [-?|--help]                 print usage" >&2
    exit 1
}

while test $# -gt 0 ; do
    case "$1" in
    -s|--sites) shift; sites="$1" ; shift ; continue;;
    -t|--today) shift; today="$1" ; shift ; continue;;
    -v|--verbose) shift; verbose=y ; continue;;
    -\?|-h|--help) usage ;;
    --) break ;;
    -*) usage ;;
    esac
    break
done

cat <<-!
Feature: redirector

Smoke tests

# Generated by redirector/tools/$cmd $(date)

!
#
#  sites.csv
#
#  1     2   3                4             5     6    7       8                9
#  Site,Host,Redirection Date,TNA Timestamp,Title,FURL,Aliases,Validate Options,New Url
#

IFS=,
tools/site_hosts.sh |
while read host
do
    grep "\b$host\b" $sites |
        cut -d , -f 1,2,3,9 |
        while read site domain redirection_date new_url
        do
            golive_date=$(echo "$redirection_date" | sed 's/\(^[0-9]*\)../\1/')

            case "$(uname)" in
            Darwin) golive=$(date -j -f "%e %B %Y" "$golive_date" +"%Y%m%d");;
            *) golive=$(date -d "$golive_date" +"%Y%m%d");;
            esac

            if [ "$today" -lt "$golive" ] ; then 
                [ -n "$verbose" ] && echo "skipping $site $host" >&2
                continue
            fi

            case "$host" in
            www.direct.gov.uk) priority=urgent;;
            $domain) priority=high;;
            *) priority=normal;;
            esac

            cat <<!
  @$priority
  Scenario: Redirect for $site from $host
    Given I am benchmarking
    When I visit "http://$host/" without following redirects
    Then I should get a 301 status code
    And I should get a location of "$new_url"
    And the elapsed time should be less than 2 seconds

!

        done
done

exit 0
