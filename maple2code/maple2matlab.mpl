
maple2matlab := proc(sym,fcn_name::string,input_list::list,par_name::string,path::string)
	description "maple2matlab is a Maple procedure that exports symbolic expressions from Maple to MATLAB.",
	"The proc exports a symbol into a file defining a MATLAB function.",
	"The list input_list defines the inputs of the function.",
	"Additional parameter(s), which are not part of input_list, ",
	"are added as a parameter struct (if multiple).",
	" ",
	"sym..........Symbol to be exported. Can be a matrix, a vector, or scalar",
	"fcn_name.....Name of the exported function as string",
	"input_list...List of function inputs",
	"par_name.....Name of parameter struct as string",
	"path.........Path for the file to be saved as string",
	"Date: 09/2024";
	# Based on export procedure TU Wien/ACIN
	
	local cg_tmp, f, i, par, ind, syms, fcn_out, rows, columns, cg_proc;

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
		  #  http://compgroups.net/comp.soft-sys.math.maple/code-generation-from-a-matrix/2418212
		  #for the original suggestion.
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
	cg_tmp:=CodeGeneration[Matlab](cg_proc,output=string,optimize=false);
     
     #Prepend all used parameters by "par_name." to make them fields of a struct.
     #For example, s__1x is replaced by par_name.s__1x
     #Elements, which are present in the parameterlist, have already been
     #removed from syms
     for i from 1 to numelems(syms) do
       cg_tmp:=StringTools[RegSubs](cat("([ (-])(",convert(syms[i],string),")([; )])")=cat("\\1",par_name,".\\2\\3"),cg_tmp);
     end do:
     #Replace the function name
     cg_tmp:=StringTools[SubstituteAll](cg_tmp,"function cg_procreturn = cg_proc(",cat("function fcn_out = ",fcn_name,"("));
     # remove last assignment (since it is assinged twice)
     ind:=StringTools[Search]("  cg_procreturn =",cg_tmp):
     cg_tmp:=StringTools[Delete](cg_tmp,ind..ind+50);
     # write "end" at the end
     cg_tmp:=StringTools[Insert](cg_tmp,ind-1,"end");
     # account for scalar case
     if rows = 1 and columns = 1 then
       	ind:=StringTools[SearchAll]("=",cg_tmp):
       	cg_tmp:=StringTools[Delete](cg_tmp,ind[nops([ind])]-3..ind[nops([ind])]-1):
       	cg_tmp:=StringTools[Insert](cg_tmp,ind[nops([ind])]-4,"fcn_out "):
     end if;
     # pre-allocation memory
     if type(sym, 'scalar') then  
       ind:=StringTools[Search]("\n",cg_tmp);
       cg_tmp:=StringTools[Insert](cg_tmp,ind,cat("% Optimized and generated from Maple\n","  fcn_out = 0;\n"));
     else
       ind:=StringTools[Search]("\n",cg_tmp);
       cg_tmp:=StringTools[Insert](cg_tmp,ind,cat("% Optimized and generated from Maple\n","  fcn_out = zeros(",rows,",",columns,");\n"));
     end;	
     #Write the resulting string
     f:=FileTools[Text][Open](cat(path,fcn_name,".m"),create,overwrite):
     FileTools[Text][WriteString](f,cg_tmp):
     FileTools[Text][Close](f):
end proc:

NULL;
