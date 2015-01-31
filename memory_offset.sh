#!/bin/bash
# Boris P.
# Like :
# include<stdio.h>
# 
# typedef struct _align
# {
#     double dbl;
#     int i;
#     char ch[3];
#     char c;
# } align;
# 
# int main(void){
#     printf("align %zu\n", sizeof(align));
#     return 0;
# }
# 

_create_file(){
    FILE=$(base64 /dev/urandom |tr -d '+/'|head -c6)
    FILE+='.c'
    printf "[+] %s created\n" "$FILE"
    echo -e "#include <stdio.h>\n\nvoid offset(void){\nchar small[17];\ngets(small);\n}\nint main(void){\noffset();\nreturn 0;\n}" > "$FILE"
}

_change_lame(){
    local sizeOfArray="$1"
    sed -ri 's/small\[.*\]/small\['"$sizeOfArray"'\]/' "$FILE"
}

_compile_lame(){
    gcc -ggdb -fno-stack-protector -z execstack "$FILE" -o "${FILE%.*}" 2> /dev/null
}

_result(){
    tput cup $X 0 ; printf "[+] Memory offset => %s\n" "$1"
}

_gdb_sub(){
    SUB=$(gdb ./"${FILE%.*}" <<< "disassemble offset" |awk '/sub/{print $4}')
    [ -z "$FIRST_SUB" ] && \
         FIRST_SUB="$SUB" || { \
            : $((C++))
            _result $C
            [ "$FIRST_SUB" != "$SUB" ] && { \
                _exit_clean
            }
        }
    echo -n ''
}

_exit_clean(){
    rm "$FILE" "${FILE%.*}"
    printf "[+] %s and %s have been removed" "$FILE" "${FILE%.*}"
    exit 0
}

########## MAIN #############
clear
trap _exit_clean SIGINT SIGKILL
_create_file
printf '\033[6n';read -sdR X; X=${X#*[} ; X=${X%;*}
echo "[+] Calcul in progress"
C=0
for size_array in {1..64}; do
    _change_lame "$size_array"
    _compile_lame
    _gdb_sub "$size_array"
done
