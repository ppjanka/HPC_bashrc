#!/usr/bin/env bash

echo "Processing bash_profile.."

. ~/.secret_pars # defines variables that should not be shared openly here, e.g., the project name MY_PROJECT

# simple everyday aliases
alias la='ls -a'
ghis () {
    local pattern=$(printf '|%s' $@)
    pattern=${pattern:1}
    history | grep -E "$pattern" | tail
}

# location shortcuts
alias cdp='cd /cfs/klemming/projects/snic/${MY_PROJECT}/$USER'
alias cds='cd /cfs/klemming/scratch/${USER:0:1}/$USER'
alias cdn='cd /cfs/klemming/nobackup/${USER:0:1}/$USER'

# check available quota
checkquota () {
    echo -e "\nProject quota for ${MY_PROJECT}:"
    lfs quota -hp `stat -c "%g" /cfs/klemming/projects/snic/${MY_PROJECT}` /cfs/klemming
    echo -e "\nUser quota for ${USER} (id $UID):"
    lfs quota -hp $UID /cfs/klemming
    echo
}

# slurm commands
# show the current user's slurm queue
alias sq='squeue -u $USER'
# show final lines of the slurm output files in the current directory
sl () {
    # parse arguments
    declare -i tail_lines=10 # number of tail lines to display
    declare -i file_from_last=0 # will read nth file from the most recent
    local sort_arg='-tr' # arguments to be passed to ls *.slurm, default: chronological
    local view_command='tail'
    for (( i=1; i<=$#; i++ )); do
        case ${!i} in
            '-n') tail_lines=${@:$((i+1)):1}; ((i++));;
            '-nf') file_from_last=${@:$((i+1)):1}; ((i++));;
            '-h') view_command='head';;
            *) echo "[$FUNCNAME] Command line option unrecognised: \"${!i}\", ignored."
        esac
    done
    # search for the desired .slurm file
    declare -a filenames=($(ls ${sort_arg} slurm*.out 2> /dev/null))
    if [ ${#filenames[@]} -eq 0 ]; then
        echo "[$FUNCNAME] No .slurm files available."
    elif [ ${#filenames[@]} -lt ${file_from_last} ]; then
        echo "[$FUNCNAME] Not enough .slurm files to satisfy the -n parameter (no. of file from last)."
    else
        local filename=${filenames[${#filenames[@]}-${file_from_last}-1]}
        # print out the desired output
        less $filename | ${view_command} -n ${tail_lines}
    fi
}

# Start the SSH agent and prompt user to provide the passphrase to the Git key
#  - note: only processes RSA keys here (easy to adjust if you need other algorithms)
start_ssh () {
    eval $(ssh-agent -s)
    for key in $@; do
        { # try: prompt user for passphrase
            ssh-add $key
            # clean the clipboard to avoid re-pasting the passphrase by mistake
            #echo | xclip -selection c # no xclip on Dardel
        } || { # catch: aborted
            echo " - ssh-key \"${key}\" init aborted."
        }
    done
}
start_ssh $(ls ~/.ssh/*rsa* 2> /dev/null | grep -v '.pub')

echo "bash_profile processing done."
