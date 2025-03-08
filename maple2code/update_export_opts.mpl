
update_export_options := proc(input_opts::list)
	# default options
	local opt_i, path_val := "./", fcn_name_val := "maple_export", par_name_val := "par", input_list_val := [], planguage_val := "MATLAB", casadi_val := false, keys_matrix_mult_val := [];

	# update options
	for opt_i from 1 to numelems(input_opts) do
		if lhs(input_opts[opt_i]) = 'path' then
	    		path_val := rhs(input_opts[opt_i]);
	    	elif lhs(input_opts[opt_i]) = 'fcn_name' then
	    		fcn_name_val := rhs(input_opts[opt_i]);
	    	elif lhs(input_opts[opt_i]) = 'par_name' then
	    		par_name_val := rhs(input_opts[opt_i]);
	    	elif lhs(input_opts[opt_i]) = 'input_list' then
	    		input_list_val := rhs(input_opts[opt_i]); 
	    	elif lhs(input_opts[opt_i]) = 'pl' then
	    		planguage_val := rhs(input_opts[opt_i]);
	    	elif lhs(input_opts[opt_i]) = 'casadi' then
	    		casadi_val := rhs(input_opts[opt_i]);
	     elif lhs(input_opts[opt_i]) = 'keys_matrix_mult' then
	    		keys_matrix_mult_val := rhs(input_opts[opt_i]);  
	    	else
	    		if lhs(input_opts[opt_i]) = 'path_m2c' then else
	    			error cat("export option not valid: ",convert(lhs(input_opts[opt_i]),string)," \n check Description(maple2code)");
	    		end if;
		end if;
	end do;

	# return updated options
	return [	path = path_val,
			fcn_name = fcn_name_val, 
			par_name = par_name_val, 
			input_list = input_list_val, 
			pl = planguage_val, 
			casadi = casadi_val, 
			keys_matrix_mult = keys_matrix_mult_val]
end proc:
NULL;
