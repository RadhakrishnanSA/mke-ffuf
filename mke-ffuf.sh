#!/usr/bin/env bash
# mke-ffuf — Focused Web Fuzzer by mke / RadhakrishnanSA

set -uo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[1;34m'; C='\033[0;36m'; W='\033[1;37m'
DIM='\033[2m'; NC='\033[0m'; BG='\033[1;32m'; BR='\033[1;31m'

# ── GLOBALS ───────────────────────────────────────────────────────────────────
TARGET=""
THREADS=20
TIMEOUT=8
RATE=0
INSECURE=0
OUTPUT_FILE=""
JSON_OUTPUT=0      # -oj flag
PROXY=""
MATCH_CODES=""
FILTER_CODES=""
WORDLIST_OVERRIDE=""
TARGET_TYPE=""
declare -a WL=()
declare -a BASE_CURL=()

results_tmp=""
lock_file=""

# ── CLEANUP / TRAP ────────────────────────────────────────────────────────────
cleanup() {
  printf "\n${Y}[!] Interrupted — cleaning up...${NC}\n"
  exec 3>&- 2>/dev/null || true
  [[ -n "$results_tmp" ]] && rm -f "$results_tmp"
  [[ -n "$lock_file"   ]] && rm -f "$lock_file"
  kill 0 2>/dev/null
  exit 130
}
trap cleanup INT TERM
umask 077   # restrict temp file permissions — prevents /tmp snooping

# ── DEPS ──────────────────────────────────────────────────────────────────────
check_deps() {
  local missing=()
  command -v curl  &>/dev/null || missing+=("curl")
  command -v flock &>/dev/null || missing+=("flock (util-linux)")
  [[ ${#missing[@]} -eq 0 ]] || { printf "${BR}[-] Missing: %s${NC}\n" "${missing[*]}"; exit 1; }
}

# ── VALIDATION ────────────────────────────────────────────────────────────────
validate_int() {
  local val="$1" name="$2" min="${3:-1}"
  [[ "$val" =~ ^[0-9]+$ ]] \
    || { printf "${BR}[-] %s must be a positive integer (got: '%s')${NC}\n" "$name" "$val"; exit 1; }
  (( val >= min )) \
    || { printf "${BR}[-] %s must be >= %s${NC}\n" "$name" "$min"; exit 1; }
}

validate_url() {
  [[ "$1" =~ ^https?:// ]] \
    || { printf "${BR}[-] Invalid URL: %s${NC}\n" "$1"; exit 1; }
}

validate_codes() {
  [[ "$1" =~ ^[0-9]+(,[0-9]+)*$ ]] \
    || { printf "${BR}[-] Invalid code list: '%s'  (use e.g. 200,301)${NC}\n" "$1"; exit 1; }
}

# ── WORDLISTS ─────────────────────────────────────────────────────────────────
WL_WORDPRESS=(
  wp-login.php wp-admin wp-admin/ wp-config.php wp-config-sample.php
  wp-cron.php wp-mail.php wp-trackback.php wp-activate.php xmlrpc.php
  wp-blog-header.php wp-comments-post.php wp-signup.php readme.html
  license.txt wp-json wp-json/wp/v2/users wp-json/wp/v2/posts
  wp-content/uploads/ wp-content/plugins/ wp-content/themes/
  wp-content/debug.log wp-includes/ wp-admin/install.php
  wp-admin/setup-config.php wp-admin/admin-ajax.php
)
WL_DRUPAL=(
  user/login user/register user/password admin/ admin/config
  admin/content admin/structure admin/appearance admin/modules
  admin/people admin/reports sites/default/files/ sites/default/settings.php
  core/ modules/ themes/ CHANGELOG.txt INSTALL.txt README.txt
  update.php install.php xmlrpc.php cron.php
)
WL_JOOMLA=(
  administrator/ administrator/index.php configuration.php
  "administrator/manifests/files/joomla.xml"
  components/ modules/ plugins/ templates/ cache/ logs/
  tmp/ language/ libraries/ media/
  "index.php?option=com_users&view=login"
)
WL_LARAVEL=(
  login register logout api/ api/user telescope telescope/
  horizon sanctum/csrf-cookie .env config/ storage/logs/
  artisan public/index.php bootstrap/cache/
)
WL_DJANGO=(
  admin/ admin/login/ accounts/login/ accounts/register/
  api/ api/v1/ static/ media/ robots.txt favicon.ico
)
WL_ASPNET=(
  login.aspx signin.aspx admin/ admin/login.aspx default.aspx
  web.config global.asax elmah.axd trace.axd api/ swagger
  WebResource.axd ScriptResource.axd
)
WL_API=(
  api api/v1 api/v2 api/v3 v1 v2 v3 graphql graphiql
  swagger swagger-ui swagger.json openapi openapi.json
  api-docs rest health status ping oauth/token auth/token
  api/users api/admin api/login api/register api/config
)
WL_GENERIC=(
  admin admin/ login login/ dashboard panel cp cpanel
  .env .git .git/config .htaccess .htpasswd robots.txt sitemap.xml
  backup backup/ config.php config.json phpinfo.php test.php
  phpmyadmin/ adminer.php api/ swagger uploads/ files/
  readme.txt README.md wp-login.php xmlrpc.php install.php
  setup.php debug.php shell.php db.sql .env.local .env.backup
  old/ dev/ staging/ beta/ temp/ tmp/ logs/ log/ storage/
  actuator health status server-status nginx_status
  graphql openapi.json swagger.json api/v1 api/v2
  .DS_Store package.json composer.json requirements.txt
  error_log access_log app.log server.log php_errors.log
)

# ── UA POOL ───────────────────────────────────────────────────────────────────
UA_POOL=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"
  "Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/605.1.15 Safari/605.1.15"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Edg/124.0.0.0"
  "curl/8.7.1"
)
rand_ua() { printf '%s' "${UA_POOL[$((RANDOM % ${#UA_POOL[@]}))]}"; }

# ── BANNER ────────────────────────────────────────────────────────────────────
banner() {
  printf "${B}"
  cat << 'EOF'
  ███╗   ███╗██╗  ██╗███████╗      ███████╗███████╗██╗   ██╗███████╗
  ████╗ ████║██║ ██╔╝██╔════╝      ██╔════╝██╔════╝██║   ██║██╔════╝
  ██╔████╔██║█████╔╝ █████╗  █████╗█████╗  █████╗  ██║   ██║█████╗
  ██║╚██╔╝██║██╔═██╗ ██╔══╝  ╚════╝██╔══╝  ██╔══╝  ██║   ██║██╔══╝
  ██║ ╚═╝ ██║██║  ██╗███████╗      ██║     ██║      ╚██████╔╝██║
  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝      ╚═╝     ╚═╝       ╚═════╝ ╚═╝
EOF
  printf "${NC}  ${DIM}Focused Web Fuzzer — by mke / RadhakrishnanSA${NC}\n\n"
}

# ── BUILD SHARED CURL FLAGS ───────────────────────────────────────────────────
# Built once after arg-parse; subshells inherit via export-as-array trick
build_curl_opts() {
  BASE_CURL=(
    -s -o /dev/null
    -w "%{http_code}|%{size_download}|%{redirect_url}"
    --connect-timeout "$TIMEOUT"
    --max-time "$(( TIMEOUT + 2 ))"
    -L --max-redirs 3
  )
  [[ $INSECURE -eq 1 ]] && BASE_CURL+=( -k )
  [[ -n "$PROXY"     ]] && BASE_CURL+=( -x "$PROXY" )
}

# ── TARGET TYPE MENU ──────────────────────────────────────────────────────────
pick_target_type() {
  printf "${W}Select target type:${NC}\n\n"
  printf "  ${C}1${NC}  WordPress\n"
  printf "  ${C}2${NC}  Drupal\n"
  printf "  ${C}3${NC}  Joomla\n"
  printf "  ${C}4${NC}  Laravel\n"
  printf "  ${C}5${NC}  Django\n"
  printf "  ${C}6${NC}  ASP.NET / IIS\n"
  printf "  ${C}7${NC}  API / REST / GraphQL\n"
  printf "  ${C}8${NC}  Generic\n"
  [[ -n "$WORDLIST_OVERRIDE" ]] && printf "  ${C}9${NC}  Custom (%s)\n" "$WORDLIST_OVERRIDE"
  printf "\n  ${Y}Choice: ${NC}"
  read -r choice

  case "$choice" in
    1) TARGET_TYPE="WordPress";  WL=("${WL_WORDPRESS[@]}") ;;
    2) TARGET_TYPE="Drupal";     WL=("${WL_DRUPAL[@]}") ;;
    3) TARGET_TYPE="Joomla";     WL=("${WL_JOOMLA[@]}") ;;
    4) TARGET_TYPE="Laravel";    WL=("${WL_LARAVEL[@]}") ;;
    5) TARGET_TYPE="Django";     WL=("${WL_DJANGO[@]}") ;;
    6) TARGET_TYPE="ASP.NET";    WL=("${WL_ASPNET[@]}") ;;
    7) TARGET_TYPE="API";        WL=("${WL_API[@]}") ;;
    8) TARGET_TYPE="Generic";    WL=("${WL_GENERIC[@]}") ;;
    9) TARGET_TYPE="Custom";     WL=() ;;
    *) printf "${BR}[-] Invalid choice.${NC}\n"; exit 1 ;;
  esac

  # Validate custom wordlist file
  if [[ "$TARGET_TYPE" == "Custom" ]]; then
    [[ -z "$WORDLIST_OVERRIDE" ]] && { printf "${BR}[-] No -w wordlist specified.${NC}\n"; exit 1; }
    [[ -f "$WORDLIST_OVERRIDE" ]] || { printf "${BR}[-] Wordlist not found: %s${NC}\n" "$WORDLIST_OVERRIDE"; exit 1; }
    mapfile -t WL < "$WORDLIST_OVERRIDE"
  fi

  # SecLists merge
  local seclists="/usr/share/seclists"
  if [[ -d "$seclists" ]]; then
    local merge_file=""
    case "$TARGET_TYPE" in
      WordPress) merge_file="${seclists}/Discovery/Web-Content/CMS/wordpress.fuzz.txt" ;;
      Drupal)    merge_file="${seclists}/Discovery/Web-Content/CMS/drupal.txt" ;;
      Generic|API) merge_file="${seclists}/Discovery/Web-Content/common.txt" ;;
    esac
    [[ -n "$merge_file" && -f "$merge_file" ]] && \
      mapfile -t -O "${#WL[@]}" WL < "$merge_file"
  fi

  # Dedup after all merges
  local dedup_tmp
  dedup_tmp=$(mktemp)
  printf '%s\n' "${WL[@]}" | sort -u > "$dedup_tmp"
  mapfile -t WL < "$dedup_tmp"
  rm -f "$dedup_tmp"

  printf "\n  ${BG}✓${NC} Mode: ${W}%s${NC}  |  Entries (deduped): ${W}%d${NC}\n\n" \
    "$TARGET_TYPE" "${#WL[@]}"
}

# ── MULTI-SAMPLE BASELINE (3-sample avg, handles variable 404 pages) ──────────
get_baseline() {
  local url="$1"
  local total=0 n=0 i

  # Separate minimal curl args for baseline (no -w pipe, just size_download)
  local extra_args=()
  [[ $INSECURE -eq 1 ]] && extra_args+=( -k )
  [[ -n "$PROXY"     ]] && extra_args+=( -x "$PROXY" )

  for (( i=0; i<3; i++ )); do
    local rand_path
    rand_path="mke-$(head -c8 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c10)"
    local sz
    sz=$(curl -s -o /dev/null -w '%{size_download}' \
      --connect-timeout "$TIMEOUT" \
      --max-time "$(( TIMEOUT + 2 ))" \
      -L --max-redirs 3 \
      "${extra_args[@]+"${extra_args[@]}"}" \
      -A "$(rand_ua)" \
      "${url}/${rand_path}" 2>/dev/null) || sz=0
    [[ "$sz" =~ ^[0-9]+$ ]] && (( sz > 0 )) && { (( total += sz )); (( n++ )); }
    sleep 0.1
  done

  (( n > 0 )) && echo $(( total / n )) || echo 0
}

# ── STATUS COLOUR ─────────────────────────────────────────────────────────────
code_colour() {
  local c="$1"
  case "$c" in
    200)             printf "${BG}${c}${NC}" ;;
    201|204)         printf "${G}${c}${NC}" ;;
    301|302|307|308) printf "${B}${c}${NC}" ;;
    401|403)         printf "${Y}${c}${NC}" ;;
    5[0-9][0-9])     printf "${R}${c}${NC}" ;;
    *)               printf "${DIM}${c}${NC}" ;;
  esac
}

# ── CODE FILTER (-mc / -fc) ───────────────────────────────────────────────────
code_in_list() {
  local code="$1" list="$2"
  local IFS=','
  local c
  for c in $list; do [[ "$c" == "$code" ]] && return 0; done
  return 1
}

should_show() {
  local code="$1"
  # -mc: explicit match list — only these pass
  if [[ -n "$MATCH_CODES" ]]; then
    code_in_list "$code" "$MATCH_CODES" && return 0 || return 1
  fi
  # -fc: explicit filter list — these are hidden
  if [[ -n "$FILTER_CODES" ]]; then
    code_in_list "$code" "$FILTER_CODES" && return 1
  fi
  # Default: drop hard negatives
  [[ "$code" =~ ^(404|400|410|000)$ ]] && return 1
  return 0
}

# ── FUZZ ──────────────────────────────────────────────────────────────────────
run_fuzz() {
  local url="$1"
  local total="${#WL[@]}"

  local rate_sleep=0
  (( RATE > 0 )) && rate_sleep=$(awk "BEGIN{printf \"%.4f\", 1/$RATE}")

  # Header
  printf "${DIM}──────────────────────────────────────────────────────${NC}\n"
  printf " ${W}Target ${NC} : ${C}%s${NC}\n" "$url"
  printf " ${W}Mode   ${NC} : %s  |  ${W}Entries${NC}: %d\n" "$TARGET_TYPE" "$total"
  printf " ${W}Threads${NC} : %s  |  ${W}Timeout${NC}: %ss  |  ${W}Rate${NC}: %s req/s\n" \
    "$THREADS" "$TIMEOUT" "$( (( RATE > 0 )) && printf "%s" "$RATE" || printf "unlimited" )"
  [[ -n "$PROXY"        ]] && printf " ${W}Proxy  ${NC} : %s\n"   "$PROXY"
  [[ -n "$MATCH_CODES"  ]] && printf " ${W}Match  ${NC} : %s\n"   "$MATCH_CODES"
  [[ -n "$FILTER_CODES" ]] && printf " ${W}Filter ${NC} : %s\n"   "$FILTER_CODES"
  [[ -n "$OUTPUT_FILE"  ]] && printf " ${W}Output ${NC} : %s\n"   "$OUTPUT_FILE"
  [[ $INSECURE -eq 1    ]] && printf " ${Y}[!] TLS verification disabled${NC}\n"
  printf "${DIM}──────────────────────────────────────────────────────${NC}\n\n"

  # Baseline
  printf "  ${DIM}Baselining (3 samples)...${NC}"
  local baseline_size
  baseline_size=$(get_baseline "$url")
  printf "\r  ${DIM}Baseline 404 avg: %s bytes${NC}                    \n" "$baseline_size"

  # Adaptive threshold: 5% of baseline, but never less than 20 bytes
  local threshold=$(( baseline_size * 5 / 100 ))
  (( threshold < 20 )) && threshold=20

  # Temp files
  results_tmp=$(mktemp /tmp/mke-res-XXXXXX)
  lock_file="${results_tmp}.lock"
  touch "$lock_file"

  # FIFO semaphore
  local fifo
  fifo=$(mktemp -u /tmp/mke-fifo-XXXXXX)
  mkfifo "$fifo"
  exec 3<>"$fifo"
  rm -f "$fifo"
  local i; for ((i=0; i<THREADS; i++)); do printf . >&3; done

  local req=0
  local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  for word in "${WL[@]}"; do
    [[ -z "$word" || "$word" =~ ^# ]] && continue
    read -r -n1 -u3     # acquire slot

    (( req++ ))
    (( RATE > 0 )) && sleep "$rate_sleep" 2>/dev/null || true

    printf "\r  ${DIM}%s  [%d/%d]${NC}" "${spin[$((req % 10))]}" "$req" "$total" >&2

    {
      local turl="${url}/${word}"
      local out
      out=$(curl "${BASE_CURL[@]}" -A "$(rand_ua)" "$turl" 2>/dev/null) || out="000|0|"

      # Parameter expansion — zero forks, fast
      local code="${out%%|*}"
      local rest="${out#*|}"
      local size="${rest%%|*}"
      local redir="${rest#*|}"

      if should_show "$code"; then
        # Soft-404 filter: skip 200s whose size is within threshold of baseline
        local skip=0
        if [[ "$code" == "200" ]] && (( baseline_size > 50 )); then
          local diff=$(( size - baseline_size ))
          (( diff < 0 )) && diff=$(( -diff ))
          (( diff <= threshold )) && skip=1
        fi

        if (( skip == 0 )); then
          # flock prevents line interleaving from concurrent subshell writes
          flock "$lock_file" \
            printf '%s|%s|%s|%s\n' "$code" "$size" "$turl" "$redir" >> "$results_tmp"
        fi
      fi

      printf . >&3     # release slot
    } &

  done

  wait
  exec 3>&-
  printf "\r%70s\r" "" >&2   # clear spinner

  # Print results — process substitution keeps found counter in current shell
  local found=0
  [[ -n "$OUTPUT_FILE" ]] && : > "$OUTPUT_FILE"  # truncate/create output file

  # Prepare output file
  if [[ -n "$OUTPUT_FILE" ]]; then
    if (( JSON_OUTPUT )); then
      printf '[\n' > "$OUTPUT_FILE"
    else
      : > "$OUTPUT_FILE"
    fi
  fi

  local first_json=1
  if [[ -s "$results_tmp" ]]; then
    while IFS='|' read -r code size furl redir; do
      (( found++ ))
      local sym rinfo=""
      [[ "$code" == "200" ]] && sym="${BG}✓${NC}" || sym="${G}*${NC}"
      [[ -n "$redir" ]] && rinfo="  ${DIM}→ ${redir}${NC}"

      printf "  %b  %b  %s  ${DIM}[%sb]${NC}%b\n" \
        "$sym" "$(code_colour "$code")" "$furl" "$size" "$rinfo"

      if [[ -n "$OUTPUT_FILE" ]]; then
        if (( JSON_OUTPUT )); then
          # One JSON object per line — jq-compatible
          local comma=""
          (( first_json )) && first_json=0 || comma=","
          local redir_json="${redir:-}"
          printf '%s{"url":"%s","status":%s,"size":%s,"redirect":"%s"}\n' \
            "$comma" "$furl" "$code" "$size" "$redir_json" >> "$OUTPUT_FILE"
        else
          local redir_plain=""
          [[ -n "$redir" ]] && redir_plain="  -> ${redir}"
          printf '[%s] [%sb] %s%s\n' "$code" "$size" "$furl" "$redir_plain" >> "$OUTPUT_FILE"
        fi
      fi

    done < <(sort -t'|' -k1,1 "$results_tmp")
  fi

  # Close JSON array
  if [[ -n "$OUTPUT_FILE" ]] && (( JSON_OUTPUT )); then
    printf '\n]\n' >> "$OUTPUT_FILE"
  fi

  printf "\n  ${BG}Done.${NC}  ${W}%d${NC} result(s) from ${W}%d${NC} requests.\n" "$found" "$req"
  [[ -n "$OUTPUT_FILE" && $found -gt 0 ]] && \
    printf "  ${DIM}Saved → %s${NC}\n" "$OUTPUT_FILE"
  printf "\n"

  rm -f "$results_tmp" "$lock_file"
  results_tmp=""; lock_file=""
}

# ── USAGE ─────────────────────────────────────────────────────────────────────
usage() {
  banner
  printf "Usage: %s -u <URL> [options]\n\n" "$0"
  printf "  ${C}-u${NC}  Target URL              (required)\n"
  printf "  ${C}-t${NC}  Threads                 [default: 20]\n"
  printf "  ${C}-T${NC}  Timeout seconds         [default: 8]\n"
  printf "  ${C}-r${NC}  Rate limit req/sec      [default: unlimited]\n"
  printf "  ${C}-w${NC}  Custom wordlist file\n"
  printf "  ${C}-o${NC}  Output file             (plain text, no colour codes)\n"
  printf "  ${C}-oj${NC} Output file (JSON)      one object per result — pipe to jq\n"
  printf "  ${C}-x${NC}  Proxy  e.g.             http://127.0.0.1:8080\n"
  printf "  ${C}-mc${NC} Match codes  e.g.       200,301\n"
  printf "  ${C}-fc${NC} Filter codes e.g.       403,500\n"
  printf "  ${C}-k${NC}  Skip TLS verification\n"
  printf "\n  ${DIM}Examples:\n"
  printf "  %s -u https://target.com\n" "$0"
  printf "  %s -u https://target.com -t 30 -o results.txt\n" "$0"
  printf "  %s -u https://target.com -x http://127.0.0.1:8080 -mc 200,301\n" "$0"
  printf "  %s -u https://target.com -fc 403 -o out.txt -k${NC}\n" "$0"
  printf "  ${DIM}%s -u https://target.com -oj -o results.json | jq .${NC}\n" "$0"
  exit 0
}

# ── ARG PARSE ─────────────────────────────────────────────────────────────────
# Handle -mc and -fc manually (getopts doesn't support long-style flags)
declare -a _remaining=()
_i=0
_args=("$@")
while (( _i < ${#_args[@]} )); do
  case "${_args[$_i]}" in
    -mc) (( _i+1 < ${#_args[@]} )) && [[ "${_args[$((_i+1))]}" != -* ]] \
           || { printf "${BR}[-] -mc requires an argument (e.g. 200,301)${NC}\n"; exit 1; }
         MATCH_CODES="${_args[$(( _i+1 ))]}";  (( _i+=2 )) ;;
    -fc) (( _i+1 < ${#_args[@]} )) && [[ "${_args[$((_i+1))]}" != -* ]] \
           || { printf "${BR}[-] -fc requires an argument (e.g. 403,500)${NC}\n"; exit 1; }
         FILTER_CODES="${_args[$(( _i+1 ))]}"; (( _i+=2 )) ;;
    -oj) JSON_OUTPUT=1;                          (( _i++ ))  ;;
    *)   _remaining+=("${_args[$_i]}");         (( _i++ )) ;;
  esac
done

# Feed cleaned args to getopts
set -- "${_remaining[@]+"${_remaining[@]}"}"
while getopts "u:t:T:r:w:o:x:kjh" opt; do
  case $opt in
    u) TARGET="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    T) TIMEOUT="$OPTARG" ;;
    r) RATE="$OPTARG" ;;
    w) WORDLIST_OVERRIDE="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    x) PROXY="$OPTARG" ;;
    k) INSECURE=1 ;;
    j) JSON_OUTPUT=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

[[ -z "$TARGET" ]] && { printf "${BR}[-] -u <URL> required.${NC}\n"; usage; }

TARGET="${TARGET%/}"
[[ "$TARGET" != http* ]] && TARGET="https://${TARGET}"

validate_url    "$TARGET"
validate_int    "$THREADS" "threads" 1
validate_int    "$TIMEOUT" "timeout" 1
(( RATE > 0 )) && validate_int "$RATE" "rate" 1
[[ -n "$MATCH_CODES"  ]] && validate_codes "$MATCH_CODES"
[[ -n "$FILTER_CODES" ]] && validate_codes "$FILTER_CODES"
[[ -n "$OUTPUT_FILE"  ]] && \
  { touch "$OUTPUT_FILE" 2>/dev/null \
    || { printf "${BR}[-] Cannot write to: %s${NC}\n" "$OUTPUT_FILE"; exit 1; }; }

check_deps
build_curl_opts

banner
pick_target_type
run_fuzz "$TARGET"
