%option noyywrap

%{

        #include <stdio.h>
        #include <string.h>
        #include <stdlib.h>
        #include "bison_code.tab.h"

        char s[1024];
        char *ptr;
        char c;
        int line = 1;
        int line_flag = 0;
        int size;

        extern FILE* fp;
        extern int warns;
        extern void warn_handle(char* txt);

        int correct_lect_counter = 0;
        int false_lect_counter = 0;
        
        int check_list(char*,int);
        int err(char*,int);
        void incr();
        int is_delimiter(char);
        void yyerror(const char* msg);
        int check_par(char*, int);
%}

DELIMITER       [ \t\n\)\(]
INTCONST        0|[+-]?[1-9][0-9]*
VARIABLE        \?([a-zA-Z]|[0-9])+
SYMBOL          \"((([^\\\\|\n|\\\"])*)|(\\(\\|n|\"))*)*\"
RULE            [a-zA-Z]([a-zA-Z]|[0-9]|-|_)*
EXP             ([e|E][+|-]?[1-9][0-9]*)?
FLOAT           [+|-]?(0|[1-9][0-9]*){EXP}\.[0-9]+{EXP}
COMMENT	        ;.*

%%
"deffacts"{DELIMITER}   { incr(); return check_list(yytext,DEFFACTS); }
"def"[a-z]{0,3}"acts"{DELIMITER}  {incr();warn_handle(yytext); return check_list(yytext,DEFFACTS); }

"defrule"{DELIMITER}    { incr(); return check_list(yytext,DEFRULE); }
"def"[a-z]{0,3}"ule"{DELIMITER}  {incr();warn_handle(yytext); return check_list(yytext,DEFRULE); }

"test"{DELIMITER}       { incr(); return check_list(yytext,TEST); }
"bind"{DELIMITER}       { incr(); return check_list(yytext,BIND); }
"read"{DELIMITER}       { incr(); return check_list(yytext,READ); }

"printout t"{DELIMITER} { incr(); return check_list(yytext,PRINTOUT); }
"printout"{DELIMITER}   { incr();warn_handle(yytext);return check_list(yytext,PRINTOUT); }

"="{DELIMITER}          { incr(); return check_list(yytext,EQUALS); }
"+"{DELIMITER}          { incr(); return check_list(yytext,PLUS); }
"-"{DELIMITER}          { incr(); return check_list(yytext,SUB); }
"*"{DELIMITER}          { incr(); return check_list(yytext,MULT); }
"/"{DELIMITER}          { incr(); return check_list(yytext,DIV); }
"("\n?                  { incr(); return check_par(yytext,LEFT_PARAM); }
")"\n?                  { incr(); return check_par(yytext,RIGHT_PARAM); }
"->"\n?                 { incr(); return check_par(yytext,ARROW); }
{INTCONST}{DELIMITER}   { incr(); return check_list(yytext,INTCONST); }
{VARIABLE}{DELIMITER}   { incr(); return check_list(yytext,VARIABLE); }
{SYMBOL}{DELIMITER}     { incr(); return check_list(yytext,SYMBOL); }
{FLOAT}{DELIMITER}      { incr(); return check_list(yytext,FLOAT); }
{RULE}{DELIMITER}       { incr(); return check_list(yytext,RULE); }
{COMMENT}\n             { incr(); correct_lect_counter++; line_flag = 1;}
{DELIMITER}             { if(!strcmp(yytext,"\n")) line++;}
.                       { incr(); return err(yytext,line); }
<<EOF>>		        { printf("#END-OF-FILE#\n"); return TERM;}

%%
// Ελέγχει εάν περιέχεται το \n και αν ναι τότε σηκώνει την σημαία line_flag.
// επίσης ανεβάζει τον μετρητή correct_lect_counter 
int check_par(char* txt, int ret){
        if ((ptr = strchr(txt,'\n'))){
                line_flag = 1;
                strcpy(txt,"\n");
        }
        correct_lect_counter++;
        return ret;
}

// Παίρνει ανα χαρακτήρα την λάθος λέξη και ψάχνει να βρεί που τελειώνει ώστε να την
// παρουσιάσει ολόκληρη ως λάθος
int err(char* yytxt,int line){
        strcpy(s,yytxt);
        while(!is_delimiter(c=input())){
                strcat(s,&c);
        }
        if(c == '\n')
                strcat(s,&c);
        strcpy(yytxt,s);
        fprintf(fp,"Line:%d\n\tLectical Error: %s\n\n",line,yytxt);
        false_lect_counter++;
        return UNKNOWN_TOKEN;
}

// Επιστρέφει true όταν βρίσκει κάποιο delimiter που σημαίνει ότι
// έφτασε στο τέλος του string, αν βρεί \n σηκώνει τη σημαία line_flag
int is_delimiter(char c){
    if (c == ' ' || c == '\n' || c == '\t' || c == EOF){
        if(c == '\n')
                line_flag = 1;
        return 1;
    }
    return 0;
}


// Κύρια συνάρτηση που αφαίρει παρενθέσεις και τις επιστρέφει πίσω για
// αναγνώριση. Επίσης αφαιρεί κενά και tab απο το τέλος της λέξης. Αν βρει
// \n τότε σηκώνει την σημαία line_flag.
int check_list(char* text,int ret){
        if ((ptr = strchr(text,'\n')))
                line_flag = 1;
        
        
        size = strlen(text) - 1;

        if(ret != 7){
                if ((text[size] == '\t') || (text[size] == ' '))
                        text[size] = '\0';

                if ((text[size] == '(') || (text[size] == ')'))
                        yyless(size);
        }
        correct_lect_counter++;
        return ret;
}

// Συνάρτηση που ελέγχει εάν η σημαία line_flag είναι 1 ώστε να αυξήσει
// τον μετρητή νέας γραμμής κατά 1
void incr(){
        if(line_flag == 1){
                line++;
                line_flag = 0;
        }
}