
NULL;
maple2python := proc(sym,fcn_name::string,input_list::list,par_name::string,path::string,casadi,keys_matrix_mult)
	description "maple2python is a Maple procedure that exports symbolic expressions from Maple to Python.",
	"The proc exports a symbol into a file defining a Python function.",
	"The list input_list defines the inputs of the function.",
	"Additional parameter(s), which are not part of input_list, ",
	"are added as a parameter dictionary (if multiple).",
	" ",
	"sym................Symbol to be exported. Can be a matrix, a vector, or scalar",
	"fcn_name...........Name of the exported function as string",
	"input_list.........List of function inputs",
	"par_name...........Name of parameter struct as string",
	"path...............Path for the file to be saved as string",
	"casadi.............Flag to include CasADi syntax in export",
	"keys_matrix_mult...List symbols where @ should be used for matrix mult. instead of *",
	"Date: 09/2024";
	# Based on export procedure TU Wien/ACIN
	local cg_tmp, f, i, par, ind, syms, fcn_out, rows, columns, cg_proc, keys_mm;
     
     # Extract symbols from sym
     syms := convert(indets(sym, 'symbol'),list):

     # Remove all elements from syms, which are part of the parameterlist
     for i from 1 to numelems(input_list) do
     	syms := subs(input_list[i]=NULL,syms);
     end do:

	# Check type of sym
	if type(sym, 'scalar') then
		fcn_out := sym: rows:=1: columns:=1: 
	else
		rows,columns:=LinearAlgebra[Dimensions](convert(sym,'Matrix'));
		#See
		# http://compgroups.net/comp.soft-sys.math.maple/code-generation-from-a-matrix/2418212
		# for the original suggestion.
		fcn_out := convert(sym,array):
	end;
     # Append the parameter struct "par_name" to the parameterlist only if
     # there are any constant parameters contained.
     if numelems(syms)>0 then
       cg_proc:=codegen[makeproc]([codegen[optimize](fcn_out,tryhard)],parameters=[op(input_list),convert(par_name,symbol)]):
     else
       cg_proc:=codegen[makeproc]([codegen[optimize](fcn_out,tryhard)],parameters=input_list):
     end:

     # Code generation
    	cg_tmp := CodeGeneration[Python](cg_proc, output = string, optimize = false);

    	# Replace all * with @ for occurences of Matrix multiplications specified through keys
	for keys_mm in keys_matrix_mult do
		cg_tmp := StringTools[SubstituteAll](cg_tmp, cat(keys_mm," *"), cat(keys_mm," @"));
	end do;

    	# Change parameters into "par['parname'] for syntax in python
    	for i from 1 to numelems(syms) do
        	cg_tmp := StringTools[RegSubs](cat("([ (-])(", convert(syms[i], string), ")([\n )])") = cat("\\1", par_name, "['\\2']\\3"), cg_tmp);
    	end do:
	
    	# Replace the function name
    	cg_tmp := StringTools[SubstituteAll](cg_tmp, "def cg_proc (", cat("def ", fcn_name, "("));

    	
    	# Function return
    	ind := StringTools[Search]("return(", cg_tmp):
    	cg_tmp := StringTools[Delete](cg_tmp, ind + 6 .. ind + 50);
    	cg_tmp := StringTools[Insert](cg_tmp, ind + 5, " fcn_out");


	# Account for scalar case
     if rows = 1 and columns = 1 then
		ind := StringTools[SearchAll]("=",cg_tmp):
		if nops([ind]) = 1 then ind := convert(ind,list): end if:
		cg_tmp:=StringTools[Delete](cg_tmp,ind[nops([ind])]-3..ind[nops([ind])]-1):
       	cg_tmp:=StringTools[Insert](cg_tmp,ind[nops([ind])]-4,"fcn_out "):
	end if:

	
	# If with casadi
    	if casadi then
    		# Import casadi
    		ind := StringTools[Search]("", cg_tmp);
    		cg_tmp := StringTools[Insert](cg_tmp, ind, cat("from casadi import *\n"));
    		# Remove all occurences of math. in the string for casadi syntax
		cg_tmp := StringTools[SubstituteAll](cg_tmp, "math.", "");
		# Pre-allocate memory
	    	if type(sym, 'scalar') then
	        	ind := StringTools[Search]("):", cg_tmp);
	        	cg_tmp := StringTools[Insert](cg_tmp, ind+1, cat(" \n # Optimized and generated from Maple\n", "    fcn_out = 0"));
	    	else
	        	ind := StringTools[Search]("):", cg_tmp);
	        	cg_tmp := StringTools[Insert](cg_tmp, ind+1, cat(" \n # Optimized and generated from Maple\n", "    fcn_out = MX.zeros(", rows, ",", columns, ")"));
	    	end if;
	else
		ind := StringTools[Search]("numpy", cg_tmp);
		if ind < 1 then
			 ind := StringTools[Search]("", cg_tmp);
			 cg_tmp := StringTools[Insert](cg_tmp, ind, cat("import numpy\n"));
		end if;
		# Pre-allocate memory
	    	if type(sym, 'scalar') then
	        	ind := StringTools[Search]("):", cg_tmp);
	        	cg_tmp := StringTools[Insert](cg_tmp, ind+1, cat(" \n # Optimized and generated from Maple\n", "    fcn_out = 0;"));
	    	else
	        	ind := StringTools[Search]("):", cg_tmp);
	        	cg_tmp := StringTools[Insert](cg_tmp, ind+1, cat(" \n # Optimized and generated from Maple\n", "    fcn_out = numpy.zeros(", rows, ",", columns, ");"));
	    	end if;
	end if;

    	# Write the resulting string to the file "<fcn_name>.m"
     f := FileTools[Text][Open](cat(path, fcn_name, ".py"), create, overwrite):
    	FileTools[Text][WriteString](f, cg_tmp):
    	FileTools[Text][Close](f):
end proc:



