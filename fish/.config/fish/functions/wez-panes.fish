function wez-panes --description "Show wezterm panes with process tree resource usage"
    # Get all processes: pid, ppid, rss (KB), %cpu, command
    set -l ps_lines (ps -eo pid=,ppid=,rss=,%cpu=,comm= 2>/dev/null)

    # Build process maps
    set -l pids
    set -l ppids
    set -l rss_vals
    set -l cpus
    set -l comms

    for line in $ps_lines
        set -l fields (string match -r '^\s*(\d+)\s+(\d+)\s+(\d+)\s+([\d.]+)\s+(.+)$' $line)
        if test (count $fields) -ge 6
            set -a pids $fields[2]
            set -a ppids $fields[3]
            set -a rss_vals $fields[4]
            set -a cpus $fields[5]
            set -a comms $fields[6]
        end
    end

    # Get wezterm panes
    set -l panes_json (wezterm cli list --format json 2>/dev/null)
    if test -z "$panes_json"
        echo "No wezterm panes found (is wezterm running?)"
        return 1
    end

    set -l pane_data (echo $panes_json | jq -r '.[] | "\(.pane_id)\t\(.tty_name)\t\(.title)\t\(.workspace)"')

    # Collect all pane info for sorting
    # Format: total_rss<TAB>workspace<TAB>title<TAB>pane_id<TAB>total_cpu<TAB>proc1<PIPE>proc2...
    set -l pane_entries

    for pane in $pane_data
        set -l parts (string split \t $pane)
        set -l pane_id $parts[1]
        set -l tty $parts[2]
        set -l title $parts[3]
        set -l workspace $parts[4]

        set -l tty_short (string replace -r '^/dev/' '' $tty)
        set -l root_pid (ps -t $tty_short -o pid= 2>/dev/null | head -1 | string trim)

        if test -z "$root_pid"
            continue
        end

        # Find all descendants
        set -l to_visit $root_pid
        set -l descendants

        while test (count $to_visit) -gt 0
            set -l current $to_visit[1]
            set -e to_visit[1]
            set -a descendants $current

            for i in (seq (count $pids))
                if test "$ppids[$i]" = "$current"
                    set -a to_visit $pids[$i]
                end
            end
        end

        # Collect stats
        set -l total_rss 0
        set -l total_cpu 0
        set -l proc_list

        for desc in $descendants
            for i in (seq (count $pids))
                if test "$pids[$i]" = "$desc"
                    set -l rss $rss_vals[$i]
                    set -l cpu $cpus[$i]
                    set -l cmd (string replace -r '.*/([^/]+)$' '$1' -- $comms[$i])
                    set cmd (string replace -r '^-' '' -- $cmd)
                    set total_rss (math "$total_rss + $rss")
                    set total_cpu (math "$total_cpu + $cpu")
                    if test $rss -gt 1024
                        set -a proc_list "$rss;$cpu;$cmd"
                    end
                    break
                end
            end
        end

        set -l procs_str (string join '|' $proc_list)
        set -a pane_entries (printf "%s\t%s\t%s\t%s\t%s\t%s" $total_rss $workspace $title $pane_id $total_cpu $procs_str)
    end

    # Sort by total_rss descending and print
    for entry in (printf '%s\n' $pane_entries | sort -t\t -k1 -rn)
        set -l e (string split \t $entry)
        set -l total_rss $e[1]
        set -l workspace $e[2]
        set -l title $e[3]
        set -l pane_id $e[4]
        set -l total_cpu $e[5]
        set -l procs_str $e[6]

        # Format memory
        set -l total_mb (math "$total_rss / 1024")
        set -l mem_str
        if test $total_mb -gt 1024
            set mem_str (printf "%.1fG" (math "$total_mb / 1024"))
        else
            set mem_str (printf "%.0fM" $total_mb)
        end

        # Print header
        set_color --bold cyan
        printf "\n[%s] %s" $workspace $title
        set_color normal
        set_color brblack
        printf "  (pane:%s, total: %s, cpu:%.1f%%)\n" $pane_id $mem_str $total_cpu
        set_color normal

        # Print processes
        if test -n "$procs_str"
            for proc in (string split '|' $procs_str | sort -t';' -k1 -rn | head -10)
                set -l p (string split ';' $proc)
                set -l mem_kb $p[1]
                set -l cpu $p[2]
                set -l cmd $p[3]

                set -l pmem_mb (math "$mem_kb / 1024")
                set -l pmem_str
                if test $pmem_mb -gt 1024
                    set pmem_str (printf "%.1fG" (math "$pmem_mb / 1024"))
                else
                    set pmem_str (printf "%.0fM" $pmem_mb)
                end

                set_color yellow
                printf "  %6s " $pmem_str
                set_color brblack
                printf "%5.1f%% " $cpu
                set_color normal
                printf "%s\n" $cmd
            end
        end
    end
    echo
end
