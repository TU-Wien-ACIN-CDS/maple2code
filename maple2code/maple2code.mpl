
maple2code := proc(sym,export_opts::list)
	description "maple2code is a Maple procedure that exports symbolic expressions to a defined programming language.",
	"The proc exports a symbol into a file defining, e.g., a MATLAB function.",
	"The list export_opts defines parameters relevant for the export.",
	" ",
	"sym..............Symbol to be exported. Can be a matrix, vector, or scalar",
	"export_opts......List holding options relevant for export.",
	"Valid options are:",
	"	path_m2c.....Path to maple2code proc. Correct path is required, e.g.,",
	"	.............\"C:/Maple/support/\"",
	"	pl...........Target programming language. Valid values",
	"	.............pl=\"MATLAB\", pl=\"Python\"",
	"	fcn_name.....Name of the exported function as string, e.g.,",
	"	.............fcn_name = \"my_export\"",
	"	input_list...List of function inputs, e.g.,",
	"	.............input_list = [in1, in2]",
	"	par_name.....Name of parameter struct as string, e.g.,",
	"	.............par_name = \"my_par\"",
	"	path.........Path of the target file as string, e.g.,",
	"	.............path =  \"./\"",
	"	casadi.......Flag to include CasADi syntax in export",
	"	.............casadi = false",
	"	keys_matrix_mult...List symbols where @ should be used instead of * for",
	"	...................matrix multiplications, e.g.,",
	"	...................keys_matrix_mult = [M__1,T]",
	"Default options are defined which are overwritten based on export_opts.",
	"Date: 09/2024";
	local m2c_opts, input_list, fcn_name, par_name, path, pl, casadi, keys_matrix_mult, path2proc, path2tmp;
	
	try
		path2proc := rhs(select(x -> lhs(x) = path_m2c, export_opts)[1]);
		path2tmp := cat(path2proc,"./update_export_opts.mpl");
		
		read path2tmp;
	catch:
		error "check if the path to maple2code proc is correctly set in export_opts := [path_m2c = path, ...]";
	end try;
	
	# Update export options
	m2c_opts := update_export_options(export_opts);
	path := rhs(m2c_opts[1]); 
	fcn_name := rhs(m2c_opts[2]); 
	par_name := convert(rhs(m2c_opts[3]),string); 
	input_list := rhs(m2c_opts[4]); 
	pl := rhs(m2c_opts[5]); 
	casadi := rhs(m2c_opts[6]);
	keys_matrix_mult := rhs(m2c_opts[7]);
	
	# Do export
	if pl = "MATLAB" then
		if casadi then
			error "export with casadi not implemented for MATLAB"
		else
			path2tmp := cat(path2proc,"./maple2matlab.mpl");
			read path2tmp;
     		maple2matlab(sym,fcn_name,input_list,par_name,path);
		end if;
     elif pl = "Python" then
     	path2tmp := cat(path2proc,"./maple2python.mpl");
		read path2tmp;
		maple2python(sym,fcn_name,input_list,par_name,path,casadi,keys_matrix_mult);
     else
     	error "desired programming language not available for export";
     end if;
     if casadi then
     	printf(" -> export to %s with casadi\n",eval(pl));
     else
     	printf(" -> export to %s\n",eval(pl));
     end if;
end proc:

NULL;
