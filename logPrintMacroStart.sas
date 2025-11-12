/*******************************************************************************
  Copyright OCS Life Sciences
********************************************************************************
  Program     : logPrintMacroStart.sas
  Author      : Jules van der Zalm
  Location    : [macro location here]
  Date (ISO)  : 2025-10-29
  Description : Output the macro name, the macro parameters and the values
                the macro parameters resolved into. This esssentially eliminates
                the need to have each macro print its own information frame in
                the log.
  Remarks     : -
********************************************************************************
  Parameters  : None
  Sample call :

    %macro report(inds=, var=, outds=);

      %logPrintMacroStart;
     
      data &outds;
        set &inds;
        keep &var.;
      run;

    %mend report;

    %report(inds=sashelp.class, var=name, outds=work.class);

********************************************************************************
  Modification history:
  Date (ISO)   User    Description
  2025-10-29   Jules   Final version for PHUSE
*******************************************************************************/

%macro logPrintMacroStart();
  
  %local name width char1 char2 trace i dsid rc name_ds mvar mvalue qid total_time;
  
  /* Find the name of the macro that called logPrintStartMacro
     and store it in &NAME. for later use. */
  %let name=%sysmexecname(%sysmexecdepth-1);

  /* This is the configuration of the frame that is printed in 
     the log. The frame looks like this:

        #=============================================================
        #  This is the start of macro DO_SOMETHING.
        #=============================================================
        #  Stack trace:
        #    -DO_SOMETHING
        #     -FINE_MORE_DATA
        #      -MAIN_MACRO
        #       -OPEN CODE
        #=============================================================
        #  Parameters used:
        #
        #    PARAM1                 = A TEXT
        #=============================================================

     The setting of WIDTH determines the width of the frame.
     The setting of CHAR1 determines the character of the horizontal lines.
     The setting of CHAR2 determines the character of the left vertical line.
  */
  %let width=60;
  %let char1=%str(=);
  %let char2=%str(#);
   
  /* Write to the log "This is the start of macro [macro name]"*/
  %put %str(&char2.)%sysfunc(repeat(&char1., &width.));
  %put %str(&char2.  This is the start of macro %upcase(&name.).);
  
  /* Write the stack trace, which shows from which macro the macro
     was called (and from which macro _that_ was called, et cetera). */
  %put %str(&char2.)%sysfunc(repeat(&char1., &width.));
  %put %str(&char2.  )Stack trace:; 
  /* Loop through all calling macros until OPEN CODE is reached. */
  %do i =0 %to %eval(%sysmexecdepth-1);
    %let trace=%sysmexecname(&i);
    %put %str(&char2.  )%sysfunc(repeat(%str( ), %eval(&i.)))-%upcase(&trace.);
  %end;
  
  /* Write the parameters and values of the calling macro. This uses
     SASHELP.VMACRO. This step does not use a DATA step so that this
     macro can also be used in macros that are used inside DATA steps.
     This step uses system functions to approach and read the VMACRO
     dataset and find the records that contain the parameters and 
     values that belong to the calling macro. */
  %put %str(&char2.)%sysfunc(repeat(&char1., &width.));  
  %put %str(&char2.  Parameters used:);
  %put %str(&char2. );
  
  %let dsid=%sysfunc(open(sashelp.vmacro));
  %let rc=%sysfunc(fetch(&dsid.));
  
  /* Loop through all records in SASHELP.VMACRO and print the parameter
     name and value if it belongs to the calling macro. */
  %do %while(&rc=0);
    %let name_ds=%sysfunc(getvarc(&dsid., 1));
    %if %lowcase(&name_ds.) = %lowcase(&name.) %then %do;
      %let mvar=%sysfunc(getvarc(&dsid., 2));
      %let mvalue=%sysfunc(getvarc(&dsid., 4));
      %put %str(&char2.   ) &mvar. %sysfunc(repeat(%str( ),%eval(20-%length(&mvar.)))) = &mvalue.;
    %end;
    %let rc=%sysfunc(fetch(&dsid.));
  %end;

  %let qid=%sysfunc(close(&dsid.));
 
  %put %str(&char2.)%sysfunc(repeat(&char1., &width.));
  
%mend logPrintMacroStart;
