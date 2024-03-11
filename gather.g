getAllGlobalVars := {} -> IDENTS_BOUND_GVARS();

maybeSimplifyName := function(name)
    if StartsWith(name, "Is") and Length(name) >= 5 then
        return name{[3..Length(name)]};
    fi;

    if StartsWith(name, "Set") and Length(name) >= 5 then
        return name{[4..Length(name)]};
    fi;

    if StartsWith(name, "Has") and Length(name) >= 5 then
        return name{[4..Length(name)]};
    fi;

    return name;
end;

simplifyName := function(name)
    local n;

    n := maybeSimplifyName(name);
    if IsBoundGlobal(n) then
        return n;
    else
        return name;
    fi;
end;


scanSyntaxTree := function(f)
    local gvars, recurse, i;
    gvars := [];

    recurse := function(treenode)
        if IsString(treenode) or IsInt(treenode) or IsBool(treenode) or IsChar(treenode) or IsFloat(treenode) then
            # do nothing
        elif IsList(treenode) then
            Perform(treenode, recurse);
        elif IsRecord(treenode) then
            if IsBound(treenode.gvar) then
                AddSet(gvars, simplifyName(treenode.gvar));
            fi;
            for i in RecNames(treenode) do
                recurse(treenode.(i));
            od;
        else
            Error("Bad Syntax Tree");
        fi;
    end;

    if IsKernelFunction(f) then
        return [];
    fi;

    recurse(SYNTAX_TREE(f));
    return gvars;
end;



getImplementations := function(op)
    local r;
    if IsOperation(op) then
        r := Flat(List([0..6], x -> MethodsOperation(op, x)));
        return List(r, x -> x.func);
    elif IsFunction(op) then
        return [op];
    fi;

    return [];
end;

getGlobalsUsedByFunc := function(op)
    local impl, i;

    impl := getImplementations(op);
    return Set(Concatenation(List(impl, x -> scanSyntaxTree(x))));
end;

getDocumentTree := function()
    local allVars, allFuncs, used, v;

    allVars := getAllGlobalVars();
    allVars := Set(allVars, simplifyName);

    allFuncs := Filtered(allVars, x -> IsFunction(ValueGlobal(x)));
    used := [];

    for v in allFuncs do
        Add(used, [v, getGlobalsUsedByFunc(ValueGlobal(v))]);
    od;

    return used;
end;

doctree := getDocumentTree();
usedFunctions := Set(Concatenation(List(doctree , x -> x[2])));

LoadPackage("datastructures");

usedCount := HashMap();
for i in doctree do
    for j in i[2] do
        if IsBound(usedCount[j]) then
            usedCount[j] := usedCount[j] + 1;
        else
            usedCount[j] := 1;
        fi;
    od;
od;

unusedFunctions := Filtered(List(doctree, x -> x[1]), x -> not(x in usedFunctions));

LoadPackage("json");

f := InputTextFile("documented.json");
docjson := JsonStreamToGap(f);
documented := Set(docjson.documented);
undocumented := Set(docjson.undocumented);
CloseStream(f);


Print("documented + used: ", Length(Filtered(usedFunctions, x -> x in documented)), "\n");
Print("documented + unused: ", Length(Filtered(unusedFunctions, x -> x in documented)), "\n");
Print("undocumented + used: ", Length(Filtered(usedFunctions, x -> x in undocumented)), "\n");
Print("undocumented + unused: ", Length(Filtered(unusedFunctions, x -> x in undocumented)), "\n");

undocount := [];
for i in undocumented do
    if usedCount[i] <> fail then
        Add(undocount, [usedCount[i], i]);
    fi;
od;
Sort(undocount);

undocunused := Set(Filtered(unusedFunctions, x -> x in undocumented));