%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #define YYSTYPE char *
    //#define YYDEBUG 1

    FILE* fp;

    extern char* yytext;
    extern int line;
    extern int correct_lect_counter;
    extern int false_lect_counter;
    
    char buffer[2048];

    int false_synt_counter = 0;
    int correct_synt_counter = 0;
    int str_size;
    int warns = 0;
    int err_flag = 0;

    void err_handle(int line,char* ytxt);
    void warn_handle(char* txt);
    void results();
%}

%token DELIMITER INTCONST VARIABLE SYMBOL RULE FLOAT COMMENT UNKNOWN TOKEN DEFFACTS DEFRULE TEST BIND READ PRINTOUT EQUALS PLUS SUB MULT DIV LEFT_PARAM RIGHT_PARAM NEWLINE ARROW UNKNOWN_TOKEN TERM
%start program

%%
program:
    program arithm_oper     { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΑριθμητική Πράξη\n\t%s\n\n",line,$2); }
    |   program dfacts      { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΟρισμός Γεγονότων\n\t%s\n\n",line,$2); }
    |   program event       { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΓεγονός\n\t%s\n\n",line,$2); }
    |   program equation    { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΣύγκριση\n\t%s\n\n",line,$2); }
    |   program t_test      { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΈλεγχος με TEST\n\t%s\n\n",line,$2); }
    |   program b_bind      { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΑνάθεση με BIND\n\t%s\n\n",line,$2); }
    |   program d_rule      { correct_synt_counter++; fprintf(fp,"Line:%d\n\tΟρισμός Κανόνα\n\t%s\n\n",line,$2); }
    |   program error       { err_handle(line,yytext); }
    |   program noack       { err_handle(line,yytext); }
    |   program TERM        { results();return 0; }
    |
    ;

// 0. ΒΑΣΙΚΑ
var:
    VARIABLE {$$ = strdup(yytext);}
    ;

int_num:
    INTCONST {$$ = strdup(yytext);}
    ;

// 1. ΓΕΓΟΝΟΤΑ
list_events:
    event   {sprintf(buffer,"%s",$1);$$ = strdup(buffer);}
    |   list_events list_events {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

event:
    LEFT_PARAM rule_doub RIGHT_PARAM    {sprintf(buffer,"(%s)",$2);$$ = strdup(buffer);}
    ;

rule_doub:
    rule_mono rule_mono {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    |   rule_doub rule_mono {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    |   rule_mono INTCONST  {sprintf(buffer,"%s %s",$1,yytext);$$ = strdup(buffer);}
    |   rule_doub INTCONST  {sprintf(buffer,"%s %s",$1,yytext);$$ = strdup(buffer);}
    |   rule_mono VARIABLE  {sprintf(buffer,"%s %s",$1,yytext);$$ = strdup(buffer);}
    |   rule_doub VARIABLE  {sprintf(buffer,"%s %s",$1,yytext);$$ = strdup(buffer);}
    ;

rule_mono:
    RULE {$$ = strdup(yytext);}
    ;


// 2. ΟΡΙΣΜΟΙ_ΓΕΓΟΝΟΤΩΝ 
dfacts:
    LEFT_PARAM DEFFACTS rule_mono list_events RIGHT_PARAM {sprintf(buffer,"(deffacts %s\t%s)",$3,$4);$$ = strdup(buffer);}
    ;


// 3. ΚΑΝΟΝΕΣ
d_rule:
    LEFT_PARAM DEFRULE rule_mono rule_atom ARROW print_out RIGHT_PARAM {sprintf(buffer,"(defrule %s %s\n\t->\n\t%s)",$3,$4,$6);$$ = strdup(buffer);}
    ;

rule_atom:
    event {sprintf(buffer,"\n\t%s",$1);$$ = strdup(buffer);}
    |   t_test  {sprintf(buffer,"\n\t%s",$1);$$ = strdup(buffer);}
    |   rule_atom rule_atom {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;


// 3.1 PRINTOUT
print_out:
    LEFT_PARAM PRINTOUT prnt RIGHT_PARAM {sprintf(buffer,"(printout t %s)",$3);$$ = strdup(buffer);}
    |   print_out print_out {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

prnt:
    prnt_text  {sprintf(buffer,"%s",$1);$$ = strdup(buffer);}
    | prnt prnt  {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

prnt_text:
    LEFT_PARAM prnt_atom RIGHT_PARAM {sprintf(buffer,"(%s)",$2);$$ = strdup(buffer);}
    ;

prnt_atom:
    SYMBOL      {$$ = strdup(yytext);}
    | VARIABLE  {$$ = strdup(yytext);}
    | prnt_atom prnt_atom   {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

// 4. ΑΡΙΘΜΗΤΙΚΕΣ_ΠΡΑΞΕΙΣ
arithm_oper:
    LEFT_PARAM operation RIGHT_PARAM {sprintf(buffer,"(%s)",$2);$$ = strdup(buffer);}
    ;

operation:
    |   PLUS expr expr {sprintf(buffer,"+ %s %s",$2,$3);$$ = strdup(buffer);}
    |   SUB  expr expr {sprintf(buffer,"- %s %s",$2,$3);$$ = strdup(buffer);}
    |   DIV  expr expr {sprintf(buffer,"/ %s %s",$2,$3);$$ = strdup(buffer);}
    |   MULT expr expr {sprintf(buffer,"* %s %s",$2,$3);$$ = strdup(buffer);}
    // NEW STUFF
    |   PLUS noack expr expr {warn_handle($2);sprintf(buffer,"+ %s %s",$3,$4);$$ = strdup(buffer);}
    |   MULT noack expr expr {warn_handle($2);sprintf(buffer,"* %s %s",$3,$4);$$ = strdup(buffer);}
    |   DIV noack expr expr {warn_handle($2);sprintf(buffer,"/ %s %s",$3,$4);$$ = strdup(buffer);}
    |   SUB noack expr expr {warn_handle($2);sprintf(buffer,"- %s %s",$3,$4);$$ = strdup(buffer);}
    ;

expr:
    ar_atom {$$ = strdup($1);}
    |   expr expr   {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

ar_atom:
    int_num {$$ = strdup($1);}
    |   var    {$$ = strdup($1);}
    ;


// 5. ΣΥΓΚΡΙΣΗ
equation:
    LEFT_PARAM EQUALS eq_atom RIGHT_PARAM {sprintf(buffer,"(= %s)",$3);$$ = strdup(buffer);}
    ;

eq_atom:
    ar_atom ar_atom {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    |   arithm_oper ar_atom {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    |   ar_atom arithm_oper {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;


// 6. ΕΛΕΓΧΟΣ_ΤΙΜΩΝ_ΜΕ_TEST
t_test:
    LEFT_PARAM TEST equation RIGHT_PARAM {sprintf(buffer,"(test %s)",$3);$$ = strdup(buffer);}
    ;


// 7. ΑΝΑΘΕΣΗ_ΤΙΜΗΣ_BIND
b_bind:
    LEFT_PARAM BIND bind_body RIGHT_PARAM {sprintf(buffer,"(bind %s)",$3);$$ = strdup(buffer);}
    ;

bind_body:
    var LEFT_PARAM READ RIGHT_PARAM {sprintf(buffer,"%s (read)",$1);$$ = strdup(buffer);}
    |   var ar_atom   {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    |   var arithm_oper {sprintf(buffer,"%s %s",$1,$2);$$ = strdup(buffer);}
    ;

noack:
    UNKNOWN_TOKEN {$$ = strdup(yytext);}
%%

// Η συνάρτηση καλείται για να εκτυπώσει το Syntax Error μια φορά ανα γραμμή
// ελέγχει εάν το string περιέχει το \n καθώς τα delimiters πάνε με την λέξη
// κι αν ναι τότε εκτυπώνει το μήνυμα
void err_handle(int line,char* txt){
    err_flag = 1;
    if(strchr(txt,'\n')){
        fprintf(fp,"Line:%d\n\tSyntax Error\n\n",line);
        false_synt_counter++;
        yyclearin;  
    }
}


// Χρησιμοποιείται για Warnings. Εάν βρει ένα τότε αυξάνεται ο μετρητής warns
// σηκώνεται η σημαία err_flag ώστε να εκτυπωθεί στο τέλος Parse Failed και
// εκτυπώνεται ανάλογο μήνυμα
void warn_handle(char* txt){
    err_flag = 1;
    warns++;
    fprintf(fp,"Line:%d\n\tWARNING: Unknown Token %s",line,txt);
    fprintf(fp,"\t%d character(s) ignored so far\n\n",warns);
}

void results(){
    printf("ΣΩΣΤΕΣ ΛΕΞΕΙΣ:    <%d>\n",correct_lect_counter);
    printf("ΣΩΣΤΕΣ ΕΚΦΡΑΣΕΙΣ: <%d>\n",correct_synt_counter);
    printf("ΛΑΘΟΣ ΛΕΞΕΙΣ:     <%d>\n",false_lect_counter);
    printf("ΛΑΘΟΣ ΕΚΦΡΑΣΕΙΣ:  <%d>\n",false_synt_counter);
    printf("ΠΡΟΕΙΔΟΠΟΙΗΣΕΙΣ:  <%d>\n",warns);
    fclose(fp);
}

int yyerror(void){}

extern FILE *yyin;

int main(int argc,char** argv){
    //yydebug = 1;
    if(argc == 2)
        yyin = fopen(argv[1],"r");
    else
        yyin = stdin;
    
    fp = fopen("output.txt","w");
    int parse = yyparse();
    
    // NEW
    if(!parse && !err_flag){
        printf("--- PARSING SUCCEDDED ---\n");
    }else{
        printf("--- PARSING FAILED ---\n");
    }
    
    return 0;
}