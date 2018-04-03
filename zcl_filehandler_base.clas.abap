CLASS zcl_filehandler_base DEFINITION
PUBLIC
ABSTRACT
CREATE PUBLIC .

  PUBLIC SECTION.
*"* public components of class ZCL_BC_FILEHANDLER_BASE
*"* do not include other source files here!!!

    INTERFACES zif_codepages_const .

    ALIASES mc_codepage_iso8859_15 FOR zif_codepages_const~mc_codepage_iso8859_15 .
    ALIASES mc_codepage_utf16_be   FOR zif_codepages_const~mc_codepage_utf16_be .
    ALIASES mc_codepage_utf16_le   FOR zif_codepages_const~mc_codepage_utf16_le .
    ALIASES mc_codepage_utf32_be   FOR zif_codepages_const~mc_codepage_utf32_be .
    ALIASES mc_codepage_utf32_le   FOR zif_codepages_const~mc_codepage_utf32_le .
    ALIASES mc_codepage_utf8       FOR zif_codepages_const~mc_codepage_utf8 .

    TYPE-POOLS abap .

    CONSTANTS mc_filename_replace TYPE dxfilename VALUE '<FILENAME>'. "#EC NOTEXT
    CONSTANTS mc_filetype_dir TYPE filetype VALUE 'DIR'.    "#EC NOTEXT
    CONSTANTS mc_filetype_file TYPE filetype VALUE 'FILE'.  "#EC NOTEXT

    DATA mt_content TYPE REF TO data .
    DATA mv_as_binary TYPE flag READ-ONLY.
    DATA mv_bom TYPE xfeld VALUE abap_true.               "#EC NOTEXT .
    DATA mv_destination TYPE ze_destination .
    DATA mv_encoding TYPE abap_encoding VALUE mc_codepage_utf8. "#EC NOTEXT .
    DATA mv_extension TYPE hcskw_file_extension .
    DATA mv_filesize TYPE i. "N2_BYTES .
    DATA mv_fullpath TYPE string .
    DATA mv_name TYPE dxfilename .
    DATA mv_path TYPE dirname_al11 .

    METHODS build_fullpath .
    METHODS constructor
      IMPORTING
        !iv_path TYPE string OPTIONAL
      EXCEPTIONS
        not_implemented .
    CLASS-METHODS create
      IMPORTING
        !iv_path        TYPE csequence
        !iv_destination TYPE ze_destination
      RETURNING
        VALUE(ro_file)  TYPE REF TO zcl_filehandler_base .
    CLASS-METHODS f4_help_all
      IMPORTING
        !iv_file_from_frontend  TYPE flag OPTIONAL
        !iv_file_from_sapserver TYPE flag OPTIONAL
      CHANGING
        !cv_fullpath            TYPE string .
    METHODS exists ABSTRACT
      RETURNING VALUE(rv_exists) TYPE abap_bool .
    METHODS delete_file
          ABSTRACT
      RETURNING
        VALUE(rv_subrc) TYPE sy-subrc .
    CLASS-METHODS get_destination
      IMPORTING
        !iv_frontend          TYPE flag
        !iv_backend           TYPE flag
      RETURNING
        VALUE(rv_destination) TYPE ze_destination .
    METHODS get_dir_content
          ABSTRACT
      IMPORTING
        !iv_path                    TYPE csequence OPTIONAL
        !iv_only_subdir             TYPE flag DEFAULT abap_false
        !iv_only_files              TYPE flag DEFAULT abap_false
        !iv_build_object            TYPE flag DEFAULT abap_false
        !iv_append_rettable         TYPE flag DEFAULT abap_false
      RETURNING
        VALUE(rt_directory_content) TYPE ztt_basic_file_list
      .
    METHODS get_filesize
      IMPORTING
        !iv_in_binary      TYPE flag DEFAULT abap_true
      RETURNING
        VALUE(rv_filesize) TYPE int4 .
    METHODS get_os
          ABSTRACT
      RETURNING
        VALUE(rv_os) TYPE sy-opsys .
    METHODS get_physical_path
      IMPORTING
        !iv_logpath     TYPE filepath-pathintern
      RETURNING
        VALUE(rv_subrc) TYPE sy-subrc .
    METHODS get_sep
          ABSTRACT
      RETURNING
        VALUE(rv_sep) TYPE char01 .
    CLASS zcl_bc_filehandler_sapserver DEFINITION LOAD .
    METHODS move_file
      IMPORTING
        !iv_destination TYPE ze_destination
        !iv_path        TYPE csequence
        !iv_copy_only   TYPE flag DEFAULT abap_false
      RETURNING
        VALUE(ro_file)  TYPE REF TO zcl_filehandler_base .
    METHODS read_file
          ABSTRACT
      IMPORTING
        !iv_read_as_binary TYPE flag DEFAULT abap_false
      EXPORTING
        !ev_length         TYPE int4 .
    METHODS replace_fullpath_variables .
    METHODS set_encoding
      IMPORTING
        !iv_encoding TYPE abap_encoding
      EXCEPTIONS
        not_supported .
    METHODS set_fullpath
      IMPORTING
        !iv_path TYPE csequence OPTIONAL
      EXCEPTIONS
        not_implemented .
    METHODS split_fullpath
      EXCEPTIONS
        not_implemented .
    METHODS write_file
          ABSTRACT
      IMPORTING
        !iv_write_as_binary TYPE flag OPTIONAL
        !iv_binsize         TYPE int4 OPTIONAL .
  PROTECTED SECTION.
*"* protected components of class ZCL_BC_FILEHANDLER_BASE
*"* do not include other source files here!!!
  PRIVATE SECTION.
*"* private components of class ZCL_BC_FILEHANDLER_BASE
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_FILEHANDLER_BASE IMPLEMENTATION.


  METHOD build_fullpath.
*vollen Pfad zusammenbauen

    CLEAR mv_fullpath.
    IF mv_name IS NOT INITIAL AND mv_extension IS NOT INITIAL.
      mv_fullpath = mv_path && get_sep( ) && mv_name && '.' && mv_extension.
    ELSEIF mv_name IS NOT INITIAL.
      mv_fullpath = mv_path && get_sep( ) && mv_name.
    ELSE.
      mv_fullpath = mv_path.
    ENDIF.

* Ersetzungen
    replace_fullpath_variables( ).

  ENDMETHOD.                    "build_fullpath


  METHOD constructor.
    IF iv_path IS NOT INITIAL.
      set_fullpath( iv_path = iv_path ).
    ENDIF.
  ENDMETHOD.                    "CONSTRUCTOR


  METHOD create.
    DATA: lv_class TYPE seoclsname.

    CASE iv_destination.
      WHEN zcl_filehandler_frontend=>mc_destination_frontend.
        lv_class = 'ZCL_BC_FILEHANDLER_FRONTEND'.
      WHEN zcl_filehandler_sapserver=>mc_destination_sap.
        lv_class = 'ZCL_BC_FILEHANDLER_SAPSERVER'.
      WHEN OTHERS.
        EXIT.
    ENDCASE.

    CREATE OBJECT ro_file TYPE (lv_class)
            EXPORTING
              iv_path = iv_path.

  ENDMETHOD.                    "create


  METHOD f4_help_all.

    CASE abap_true.
      WHEN iv_file_from_frontend.
        zcl_filehandler_frontend=>f4_help( CHANGING cv_fullpath = cv_fullpath ).
      WHEN iv_file_from_sapserver.
        zcl_filehandler_sapserver=>f4_help( CHANGING cv_fullpath = cv_fullpath ).
      WHEN OTHERS.
        "ok ??? :D
    ENDCASE.

  ENDMETHOD.


  METHOD get_destination.

    IF iv_frontend = abap_true.
      rv_destination = zcl_filehandler_frontend=>mc_destination_frontend.
    ELSEIF iv_backend = abap_true.
      rv_destination = zcl_filehandler_sapserver=>mc_destination_sap.
    ELSE.
      CLEAR rv_destination.
    ENDIF.

  ENDMETHOD.


  METHOD get_filesize.

    FIELD-SYMBOLS: <table> TYPE table,
                   <line>  TYPE any.

    rv_filesize = -1.
    ASSIGN mt_content->* TO <table>.
    CHECK sy-subrc = 0.

    rv_filesize = 0.
    LOOP AT <table> ASSIGNING <line>.
      IF iv_in_binary = abap_true.
        rv_filesize = rv_filesize + xstrlen( <line> ).
      ELSE.
        rv_filesize = rv_filesize + strlen( <line> ).
      ENDIF.
    ENDLOOP.

  ENDMETHOD.                    "GET_FILESIZE


  METHOD get_physical_path.

    DATA:
      lv_file LIKE mv_name,
      lv_pres TYPE abap_bool.

* Suche den Dateinamen zusammen
    IF mv_name IS INITIAL AND mv_fullpath IS NOT INITIAL.
      split_fullpath( ).
      lv_file = mv_name.
    ENDIF.

    IF mv_name IS INITIAL.
      lv_file = mc_filename_replace.
      mv_name = mc_filename_replace.
    ELSE.
      lv_file = mv_name.
    ENDIF.

* Wo sind wir?
    IF mv_destination = zcl_filehandler_frontend=>mc_destination_frontend.
      lv_pres = abap_true.
    ENDIF.

    CALL FUNCTION 'FILE_GET_NAME_USING_PATH'
      EXPORTING
        logical_path               = iv_logpath
        file_name                  = lv_file
        use_presentation_server    = lv_pres
        eleminate_blanks           = abap_false
      IMPORTING
        file_name_with_path        = mv_fullpath
      EXCEPTIONS
        path_not_found             = 1
        missing_parameter          = 2
        operating_system_not_found = 3
        file_system_not_found      = 4
        OTHERS                     = 5.
    rv_subrc = sy-subrc.

    IF rv_subrc = 0.
      split_fullpath( ).
    ENDIF.

  ENDMETHOD.                    "get_physical_path


  METHOD move_file.

* erstelle die neue Datei
    ro_file = create( iv_path        = iv_path
    iv_destination = iv_destination    " Ziel des Datenstroms
    ).
    IF ro_file IS NOT BOUND.
      RETURN.
    ENDIF.

* übertrage die Daten
    ro_file->mt_content   = me->mt_content.
    ro_file->mv_filesize  = me->mv_filesize.   "Größe der gespeicherten Datei IN Bytes
    ro_file->mv_as_binary = me->mv_as_binary.  "wurde die Datei binär gelesen?

* schreibe die Daten an die neue Position
    ro_file->write_file( iv_write_as_binary = ro_file->mv_as_binary ).

* lösche die alte Datei
    IF iv_copy_only = abap_false.
      me->delete_file( ).
    ENDIF.

  ENDMETHOD.


  METHOD replace_fullpath_variables.

    DATA: lv_repl(3).

* Sys-ID ... in allen Schreibweisen wegfangen ^^
    REPLACE ALL OCCURRENCES OF '<sys-id>' IN mv_fullpath WITH sy-sysid IGNORING CASE.
    REPLACE ALL OCCURRENCES OF '<sys-id>' IN mv_path WITH sy-sysid IGNORING CASE.

* Env-ID ... Das macht schon Spaß
    IF sy-sysid = 'C12' OR sy-sysid = 'PB5' OR sy-sysid = 'PX5'.
      lv_repl = 'px5'.
    ELSE.
      lv_repl = 'ex5'.
    ENDIF.

    REPLACE ALL OCCURRENCES OF '<env-id>' IN mv_fullpath WITH lv_repl IGNORING CASE.
    REPLACE ALL OCCURRENCES OF '<env-id>' IN mv_path WITH lv_repl IGNORING CASE.

  ENDMETHOD.                    "replace_fullpath_variables


  METHOD set_encoding.

    IF   iv_encoding <> mc_codepage_iso8859_15
     AND iv_encoding <> mc_codepage_utf16_be
     AND iv_encoding <> mc_codepage_utf16_le
     AND iv_encoding <> mc_codepage_utf32_be
     AND iv_encoding <> mc_codepage_utf32_le
     AND iv_encoding <> mc_codepage_utf8.
      RAISE not_supported.
    ENDIF.

    mv_encoding = iv_encoding.
    IF   mv_encoding = mc_codepage_utf16_be
      OR mv_encoding = mc_codepage_utf16_le
      OR mv_encoding = mc_codepage_utf32_be
      OR mv_encoding = mc_codepage_utf32_le.
      mv_bom = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD set_fullpath.
    IF iv_path IS SUPPLIED.
      mv_fullpath = iv_path.
    ELSEIF mv_path IS  NOT INITIAL OR mv_name IS NOT INITIAL.
      IF mv_extension IS INITIAL.
        mv_fullpath = mv_path && get_sep( ) && mv_name.
      ELSE.
        mv_fullpath = mv_path && get_sep( ) && mv_name && '.' && mv_extension.
      ENDIF.
    ELSE.
      RAISE not_implemented .
    ENDIF.

    replace_fullpath_variables( ).
*  CHECK mv_fullpath IS NOT INITIAL.
*  split_fullpath( ).
  ENDMETHOD.                    "SET_FULLPATH


  METHOD split_fullpath.

    DATA: lv_sep(2),
          lv_regex TYPE string.

    CHECK mv_fullpath IS NOT INITIAL.
    lv_sep = get_sep( ).

    IF lv_sep = '\'.
      lv_sep = '\\'.
    ENDIF.

    lv_regex = '(.*)' && lv_sep && '(.*)\.(.*)$'.
    CONDENSE lv_regex.
* Alles auf einmal, wenn wir die richtige "normale" Form haben
    FIND FIRST OCCURRENCE OF REGEX lv_regex IN mv_fullpath SUBMATCHES mv_path mv_name mv_extension.
    CHECK sy-subrc <> 0. "Im Fehlerfall Probieren wir noch was ... :)

    IF mv_fullpath CA '\/'.
      CLEAR lv_regex.
      lv_regex = '(.*)' && lv_sep && '(.*)'.
      CONDENSE lv_regex.
      FIND FIRST OCCURRENCE OF REGEX lv_regex IN mv_fullpath SUBMATCHES mv_path mv_name.
      CHECK sy-subrc <> 0. "Im Fehlerfall Probieren wir noch was ... :)
    ELSEIF mv_fullpath CA '.'.
      CLEAR lv_regex.
      lv_regex = '(.*)\.(.*)$'.
      FIND FIRST OCCURRENCE OF REGEX lv_regex IN mv_fullpath SUBMATCHES mv_path.
      CHECK sy-subrc <> 0. "Im Fehlerfall Probieren wir noch was ... :)
    ENDIF.

* Alles andere kommt nachher
    RAISE not_implemented.

  ENDMETHOD.                    "split_fullpath
ENDCLASS.
