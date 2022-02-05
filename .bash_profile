#!/usr/bin/env bash

echo "Processing bash_profile.."

. ~/.secret_pars # defines variables that should not be shared openly here, e.g., the project name MY_PROJECT

# simple everyday aliases
alias la='ls -a'

# location shortcuts
alias cdp='cd /cfs/klemming/projects/snic/${MY_PROJECT}/$USER'
alias cds='cd /cfs/klemming/scratch/${USER:0:1}/$USER'

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

# start the SSH agent and prompt user to provide the passphrase to the Git key
start_ssh () {
    eval $(ssh-agent -s)
    declare -a keys_to_load=($@)
    for key in keys_to_load; do
        local passphrase
        read -sp "Please provide passphrase for the SSH key \"${key}\".. " passphrase
        if [ -n passphrase ]; then # if not empty
            ssh-add key -p $passphrase
        else
            echo " - ssh-key \"${key}\" init aborted."
        fi
    done
}
ls -I '*.pub' -I 'known_hosts' -I 'config' ~/.ssh/* | start_ssh

echo "bash_profile processing done."