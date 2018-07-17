
Determining the missing number and duplicates in a list of numbers

Same result in WPS and SAS if you move the DOSUBL outside the datastep.

I tried a HASH, see end of message

Nice HASh solution on end by
Bartosz Jablonski
Bartosz Jablonski's profile photo
yabwon@gmail.com

see github
https://tinyurl.com/y86bpfwz
https://github.com/rogerjdeangelis/utl_determining_the_missing_number_and_duplicates_in_a_list_of_numbers

stackoverflow
https://tinyurl.com/y7ce9wav
https://stackoverflow.com/questions/51340316/determining-the-missing-number-with-duplicates-in-the-list


INPUT
=====

 WORK.HAVE total obs=13

          |  RULES (first sort)
          |
  NUM     |   NUM

   22     |    10
   14     |    11
   19     |    12
   17     |       13 Output 13 because it is missing
               14
   15     |    15
   12     |    15 15 Outout 15 because it is duplicated

   10     |    16
   16     |    17
   17     |    17 17 Outout 17 because it is duplicated
                  18 Output 18 because it is missing
   22     |    19

   11     |    20
                  21 Output 21 because it is missing
   15     |    22
   20     |    22 22 Outout 22 because it is duplicated
          |

 EXAMPLE OUTPUT
 --------------

 WORK.WANT

   NUM    STATUS

    13    Missing
    15    Dups
    17    Dups
    18    Missing
    21    Missing
    22    Dups


PROCESS
=======

data want(keep=num status);

  * get the meta data;
  if _n_=0 then do;
     %let rc=%sysfunc(dosubl('
        proc sql;
           select
               min(num)
              ,max(num)
           into
              :_min trimmed
             ,:_max trimmed
           from
              have
        ;quit;
     '));
     array nums[&_min:&_max] _temporary_ (%eval( &_max - &_min +1 ) * 0);
  end;

  set have end=dne;

  nums[num]=nums[num]+1;

  if dne then do;

     do num=&_min to &_max;

       select;
          when (nums(num)=0) do; status="Missing"; number=num; output;end;
          when (nums(num)>1) do; status="Dups";    number=num; output;end;
          otherwise;
       end;

     end;
  end;

run;quit;


OUTPUT
======

 WORK.WANT

   NUM    STATUS

    13    Missing
    15    Dups
    17    Dups
    18    Missing
    21    Missing
    22    Dups

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

data have;
 input num;
cards4;
22
14
19
17
15
12
10
16
17
22
11
15
20
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

* SAS  see process;


*WPS Same as SAS;
%utl_submit_wps64('
libname wrk sas7bdat "%sysfunc(pathname(work))";

proc sql;
   select
       min(num)
      ,max(num)
   into
      :_min trimmed
     ,:_max trimmed
   from
      wrk.have
;quit;

data wrk.want(keep=num status);

  array nums[&_min:&_max] _temporary_ (%eval( &_max - &_min +1 ) * 0);

  set wrk.have end=dne;

  nums[num]=nums[num]+1;

  if dne then do;

     do num=&_min to &_max;

       select;
          when (nums(num)=0) do; status="Missing"; number=num; output;end;
          when (nums(num)>1) do; status="Dups";    number=num; output;end;
          otherwise;
       end;

     end;
  end;

run;quit;
');

*_               _             _   _                       _
| |__   __ _ ___| |__     __ _| |_| |_ ___ _ __ ___  _ __ | |_
| '_ \ / _` / __| '_ \   / _` | __| __/ _ \ '_ ` _ \| '_ \| __|
| | | | (_| \__ \ | | | | (_| | |_| ||  __/ | | | | | |_) | |_
|_| |_|\__,_|___/_| |_|  \__,_|\__|\__\___|_| |_| |_| .__/ \__|
                                                    |_|
;
data want;
if 0 then set have;
declare hash h(dataset: "have",ordered:"A");
_rc_ = h.DefineKey("num");
_rc_ = h.DefineDone();
retain cnt 0;
    do vals=min(h.values()) to max(h.values());
      if h.find(key: vals)=0 then continue;
      else put vals " not in list";
    end;
  stop;
run;quit;

NOTE: There were 13 observations read from the data set WORK.HAVE.
ERROR: Unknown method VALUES for DATASTEP.HASH at line 157 column 36.
ERROR: DATA STEP Component Object failure.  Aborted during the EXECUTION phase.
162 !     quit;
NOTE: The SAS System stopped processing this step because of errors.





*____             _
| __ )  __ _ _ __| |_
|  _ \ / _` | '__| __|
| |_) | (_| | |  | |_
|____/ \__,_|_|   \__|

;

/*the code*/
data have;
input number;
cards;
22
19
17
14
15
12
10
16
17
22
11
15
20
;
run;

data want;

length number 8 reason $ 10; keep number reason /* count */ ; /* <- if you need to see number od duplicates */
declare hash h(ordered: "a");
_rc_ = h.definekey("number");
_rc_ = h.definedata("count"); /* it can be replaced with suminc */
_rc_ = h.definedone();
_rc_ = h.clear();

do until(eof);
    set have end = eof;

    _MIN_ = _MIN_ <> -number;
    _MAX_ = _MAX_ <> number;

    if h.find() ^= 0 then do; count = 1; _rc_ = h.add(); end;
                     else do; count = count + 1; _rc_ = h.replace(); end;
end;

put _all_;
number = .;
reason = "";

do number = -_MIN_ to _MAX_ by 1;
    if h.find() = 0 then do; if count > 1 then do; reason = 'double'; output; end; end;
                    else do; reason = 'missing'; output; end;
    count = .;
end;

stop;
run;
proc print;
run;

/* the output
 Obs    number    reason

  1       13      missing
  2       15      double
  3       17      double
  4       18      missing
  5       21      missing
  6       22      double
*/



