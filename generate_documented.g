

all_gvars := IDENTS_BOUND_GVARS();

documented := [];
undocumented := [];

for i in [1..Length(all_gvars)] do
    if i mod 100 = 0 then
        Print(i, " of ", Length(all_gvars), "\n");
    fi;
    if IsDocumentedWord(all_gvars[i]) then
        Add(documented, all_gvars[i]);
    else
        Add(undocumented, all_gvars[i]);
    fi;
od;
# documented := Filtered(all_gvars, IsDocumentedWord);

LoadPackage("json");

file := OutputTextFile("documented.json", false);
GapToJsonStream(file,
    rec(documented := documented,
        undocumented := undocumented)
    );

CloseStream(file);