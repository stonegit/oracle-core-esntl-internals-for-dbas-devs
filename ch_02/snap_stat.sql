rem
rem	Script:		snap_stat.sql
rem	Author:		Jonathan Lewis
rem	Dated:		March 2001
rem	Purpose:	Package to get snapshot start and delta of v$sysstat
rem
rem	Notes
rem	Has to be run by SYS to create the package
rem	
rem	Usage:
rem		set serveroutput on size 1000000 format wrapped
rem		set linesize 120
rem		set trimspool on
rem		execute snap_stats.start_snap
rem		-- do something
rem		execute snap_stats.end_snap
rem

create or replace package snap_stats as
	procedure start_snap;
	procedure end_snap (i_limit in number default 0);
end;
/

create or replace package body snap_stats as

cursor c1 is
	select 
		statistic#, 
		name,
		value
	from 
		v$sysstat
	;


	type w_type is table of c1%rowtype index by binary_integer;
	w_list		w_type;
	w_empty_list	w_type;

	m_start_time	date;
	m_start_flag	char(1);
	m_end_time	date;

procedure start_snap is
begin

	m_start_time := sysdate;
	m_start_flag := 'U';
	w_list := w_empty_list;

	for r in c1 loop
		w_list(r.statistic#).value := r.value;
	end loop;

end start_snap;


procedure end_snap (i_limit in number default 0) 
is
begin

	m_end_time := sysdate;

	dbms_output.put_line('---------------------------------');
	dbms_output.put_line('System stats:-  ' ||
				to_char(m_end_time,'dd-Mon hh24:mi:ss')
	);

	if m_start_flag = 'U' then
		dbms_output.put_line('Interval:-      '  || 
				trunc(86400 * (m_end_time - m_start_time)) ||
				' seconds'
		);
	else
		dbms_output.put_line('Since Startup:- ' || 
				to_char(m_start_time,'dd-Mon hh24:mi:ss')
		);
	end if;

	if (i_limit != 0) then
		dbms_output.put_line('Lower limit:-  '  || i_limit);
	end if;

	dbms_output.put_line('---------------------------------');

	dbms_output.put_line(
		rpad('Name',60) ||
		lpad('Value',18)
	);

	dbms_output.put_line(
		rpad('----',60) ||
		lpad('-----',18)
	);

	for r in c1 loop
		if (not w_list.exists(r.statistic#)) then
		    w_list(r.statistic#).value := 0;
		end if;

		if (
		       (r.value > w_list(r.statistic#).value + i_limit)
		) then
			dbms_output.put(rpad(r.name,60));
			dbms_output.put(to_char(
				r.value - w_list(r.statistic#).value,
					'9,999,999,999,990'));
			dbms_output.new_line;
		end if;
	end loop;

end end_snap;

begin

	select
		startup_time, 'S'
	into
		m_start_time, m_start_flag
	from
		v$instance
	;

end snap_stats;
/


drop public synonym snap_stats;
create public synonym snap_stats for snap_stats;
grant execute on snap_stats to public;
