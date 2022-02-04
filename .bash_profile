#!/usr/bin/env bash

. ~/.secret_pars # contains variables I would rather not share openly here, e.g., project name MY_PROJECT

alias cdp='cd /cfs/klemming/projects/snic/${MY_PROJECT}/$USER'
alias cds='cd /cfs/klemming/scratch/${USER:0:1}/$USER'

# slurm commands
alias sq='squeue -u $USER'
sl () { # quick view of the slurm output
    # parse arguments
    declare -i tail_lines=25 # number of tail lines to display
    declare -i file_from_last=0 # will read nth file from the most recent
    local sort_arg='-t' # arguments to be passed to ls *.slurm
    local view_command='tail'
    if [ $# -gt 0 ]; then
        for (( i=1; i<=$#; i++ )); do
            case ${!i}
                '-n') tail_lines=${!$((i+1))}; ((i++));;
                '-nf') file_from_last=${!$((i+1))}; ((i++));;
                '-h') view_command='head';;
                *) echo "[$FUNCNAME] Command line option unrecognised: \"${!i}\", ignored."
            esac
        done
    fi
    # search for the desired .slurm file
    declare -a filenames=($(ls ${sort_arg} *.slurm))
    if [ ${#filenames[@]} -eq 0 ]; then
        echo "[$FUNCNAME] No .slurm files available."
    elif [ ${#filenames[@]} -lt ${file_from_last} ]
        echo "[$FUNCNAME] Not enough .slurm files to satisfy the -n parameter (no. of file from last)."
    else
        local filename=${filenames[${#filenames[@]}-${file_from_last}]}
        # print out the desired output
        less filename | ${view_command} -n ${tail_lines}
    fi
}

sl