import argparse
from sys import stderr

# Indent and use linebreaks for the children of nodes of given types.
# Only do this for the first certain number of types of nodes.
numberofindentednodes = 4

# Error handler
def error(message):
    print("Error: " + message, file=stderr)
    exit(1)

# File writing wrapper function
def writeline(file, line):
    file.write(line + "\n")

# Class for child relationships between nodes
class Child():
    def __init__(self, name, vector, optional):
        self.name = name
        self.list = vector
        self.optional = optional
    
    def __str__(self):
        string = ""
        if (self.list):
            string = string + "*"
        elif (self.optional):
            string = string + "?"
        string = string + self.name
        return string

# Class for AST Nodes read from def file
class ASTNode():
    def __init__(self, name, superclass, indent=False):
        self.name = name
        self.superclass = superclass
        self.indent = indent
        self.children = []
    
    def __str__(self):
        string = ""
        if (self.superclass):
            string = string + self.superclass + ":"
        string = string + self.name
        string = string + "("
        string = string + ", ".join([str(child) for child in self.children])
        string = string + ")"
        return string
    
    def addChild(self, name, vector, optional):
        self.children.append(Child(str(name), bool(vector), bool(optional)))
    

# Parse command line arguments, allowing specification of input and output files as well as verbosity
parser = argparse.ArgumentParser(description="Generate AST code. Read definitions from an input file and generate output .cpp and .hpp files.")
parser.add_argument("-o", metavar="name", type=str, default="ast", help="Basename to use for output files")
parser.add_argument("-i", metavar="file", type=str, default="lang.def", help="Input def file")
parser.add_argument("-v", action="store_true", help="Verbose command line output")
args = parser.parse_args()

verbose = args.v

# Handle input and output files
inputfilename = args.i
outputname = args.o
codefilename = outputname + ".cpp"
headerfilename = outputname + ".hpp"

# Print runtime options information if we are verbose
if (verbose):
    print("Reading definitions from " + inputfilename + " and outputting to " + codefilename + " and " + headerfilename)

# Try to open input file
try:
    inputfile = open(inputfilename, "r")
except IOError as e:
    error("cannot open input file")

nodes = []
abstractnodes = []

# Read all definitions (one per line)
for line in inputfile:
    # Skip comments and empty lines
    if (line.startswith("#") or len(line.strip()) < 1):
        continue
    
    # Parse left/right sides of arrow
    sides = line.strip().split("=>")
    if (len(sides) < 2):
        error("badly formatted input file")
    
    name = sides[0].strip()
    superclass = None
    
    # Check if indent node
    indent = False
    if("'" in sides[1]):
        indent = True

    # Check for superclass
    if (":" in name):
        nameparts = name.split(":")
        name = nameparts[1]
        superclass = nameparts[0]
        # Superclasses are all abstract
        # Add the current superclass found if it hasn't already been found previously
        if (superclass not in abstractnodes):
            abstractnodes.append(superclass)
    
    node = ASTNode(name, superclass, indent)
    nodes.append(node)
    
    # Handle children
    children = sides[1].strip("'").split()
    for child in children:
        childname = child
        vector = False
        optional = False
        # List children
        if (child.startswith("*")):
            childname = child.replace("*", "")
            vector = True
        # Optional children
        if (child.startswith("?")):
            childname = child.replace("?", "")
            optional = True
        node.addChild(childname, vector, optional)

# Print all definitions read from def file if we are verbose
if (verbose):
    [print("Found node def: " + str(node)) for node in nodes]

# Close input file
inputfile.close()

# Try to open both output files
try:
    headerfile = open(headerfilename, "w+")
except IOError as e:
    error("cannot open header output file")

try:
    codefile = open(codefilename, "w+")
except IOError as e:
    error("cannot open code output file")

# Output the header file (refer to inline C comments for meaning of C code)
writeline(headerfile, "#ifndef __AST_HPP")
writeline(headerfile, "#define __AST_HPP")
writeline(headerfile, "")
writeline(headerfile, "#include <iostream>")
writeline(headerfile, "#include <list>")
writeline(headerfile, "#include <vector>")
writeline(headerfile, "#include <stack>")
writeline(headerfile, "#include <string>")
writeline(headerfile, "#include <sstream>")
writeline(headerfile, "")
writeline(headerfile, "// Enumaration of all base types in the language")
writeline(headerfile, "typedef enum {bt_integer, bt_boolean, bt_none, bt_object} BaseType;")
writeline(headerfile, "")
writeline(headerfile, "// Forward declarations of AST Node classes")
for node in nodes:
    writeline(headerfile, "class " + node.name + "Node;")
writeline(headerfile, "")
for abstractnode in abstractnodes:
    writeline(headerfile, "")
    writeline(headerfile, "class " + abstractnode + "Node;")

writeline(headerfile, "")
writeline(headerfile, "class IdentifierNode;")
writeline(headerfile, "class IntegerNode;")
writeline(headerfile, "")
writeline(headerfile, "// Check order of inclusion")
writeline(headerfile, "#ifdef YYSTYPE_IS_TRIVIAL")
writeline(headerfile, "#error Make sure to include this file BEFORE parser.hpp")
writeline(headerfile, "#endif")
writeline(headerfile, "")
writeline(headerfile, "// Define YYSTYPE (type of all $$, $N variables) as a union")
writeline(headerfile, "//   of all necessary pointers (including lists). This will")
writeline(headerfile, "//   be used in %type specifiers and in lexer.")
writeline(headerfile, "typedef union {")
types = []
for node in nodes:
    if ((node.name + "Node*", node.name.lower()) not in types):
        types.append((node.name + "Node*", node.name.lower()))
    for child in node.children:
        newtype = child.name + "Node*"
        newname = child.name.lower()
        if (child.list):
            newtype = "std::list<" + child.name + "Node*" + ">*"
            newname = child.name.lower() + "_list"
        if ((newtype, newname) not in types):
            types.append((newtype, newname))

for absractnode in abstractnodes:
    if ((absractnode + "Node*", absractnode.lower()) not in types):
        types.append((absractnode + "Node*", absractnode.lower()))

for typepair in types:
    writeline(headerfile, "  " + typepair[0] + " " + typepair[1] + "_ptr;")

writeline(headerfile, "  char* base_char_ptr;")
writeline(headerfile, "  int base_int;")
writeline(headerfile, "} astnode_union;")
writeline(headerfile, "#define YYSTYPE astnode_union")
writeline(headerfile, "")
writeline(headerfile, "// Define abstract base class for all Visitors")
writeline(headerfile, "class Visitor {")
writeline(headerfile, "public:")
writeline(headerfile, "  // Declare all virtual visitor functions (all must be implemented in visitors)")
for node in nodes:
    writeline(headerfile, "  virtual void visit" + node.name + "Node(" + node.name + "Node* node) = 0;")
writeline(headerfile, "  virtual void visitIdentifierNode(IdentifierNode* node) = 0;")
writeline(headerfile, "  virtual void visitIntegerNode(IntegerNode* node) = 0;")
writeline(headerfile, "};")
writeline(headerfile, "")
writeline(headerfile, "// Define abstract base class for all AST Nodes")
writeline(headerfile, "//   (this also serves to define the visitable objects)")
writeline(headerfile, "class ASTNode {")
writeline(headerfile, "public:")
writeline(headerfile, "  // All AST nodes have a member which stores their basetype (int, bool, none, object)")
writeline(headerfile, "  //   Further type information will come from the symbol table.")
writeline(headerfile, "  BaseType basetype;")
writeline(headerfile, "")
writeline(headerfile, "  // All AST nodes provide visit children and accept methods")
writeline(headerfile, "  virtual void visit_children(Visitor* v) = 0;")
writeline(headerfile, "  virtual void accept(Visitor* v) = 0;")
writeline(headerfile, "};")
writeline(headerfile, "")
writeline(headerfile, "// Define all abstract AST node classes")
for abstractnode in abstractnodes:
    writeline(headerfile, "class " + abstractnode + "Node : public ASTNode {};")

writeline(headerfile, "")
writeline(headerfile, "// Define leaf AST nodes for ids and ints (also used for bools)")
writeline(headerfile, "// Identifiers have a member name, which is a string")
writeline(headerfile, "class IdentifierNode : public ASTNode {")
writeline(headerfile, "public:")
writeline(headerfile, "  std::string name;")
writeline(headerfile, "  virtual void visit_children(Visitor* v) { /* No Children */ }")
writeline(headerfile, "  virtual void accept(Visitor* v) { v->visitIdentifierNode(this); }")
writeline(headerfile, "  IdentifierNode(std::string name) { this->name = name; }")
writeline(headerfile, "")
writeline(headerfile, "};")
writeline(headerfile, "")
writeline(headerfile, "// Integers have a member value, which is a C int")
writeline(headerfile, "class IntegerNode : public ASTNode {")
writeline(headerfile, "public:")
writeline(headerfile, "  int value;")
writeline(headerfile, "")
writeline(headerfile, "  virtual void visit_children(Visitor* v) {/* No Children */ }")
writeline(headerfile, "  virtual void accept(Visitor* v) { v->visitIntegerNode(this); }")
writeline(headerfile, "")
writeline(headerfile, "  IntegerNode(int value) { this->value = value; }")
writeline(headerfile, "};")
writeline(headerfile, "")
writeline(headerfile, "// Define all other AST nodes")
writeline(headerfile, "")
for node in nodes:
    writeline(headerfile, "// AST Node for " + node.name)
    if (node.superclass):
        writeline(headerfile, "class " + node.name + "Node : public " + node.superclass + "Node {")
    else:
        writeline(headerfile, "class " + node.name + "Node : public ASTNode {")
    writeline(headerfile, "public:")
    writeline(headerfile, "  virtual void visit_children(Visitor* v);")
    writeline(headerfile, "  virtual void accept(Visitor* v) { v->visit" + node.name + "Node(this); }")
    if (len(node.children) > 0):
        writeline(headerfile, "")

    dupnames = {}
    childnames = []
    members = []
    for child in node.children:
        if (child.name in childnames):
            dupnames[child.name] = 1
        else:
            childnames.append(child.name)
    for child in node.children:
        number = ""
        if (child.name in dupnames.keys()):
            number = "_" + str(dupnames[child.name])
            dupnames[child.name] = dupnames[child.name] + 1

        if (not child.list):
            members.append(child.name + "Node* " + child.name.lower() + number)
        else:
            members.append("std::list<" + child.name + "Node*" + ">* " + child.name.lower() + "_list" + number)
    
    for member in members:
        writeline(headerfile, "  " + member + ";")
    
    if (len(members) > 0):
        writeline(headerfile, "")
        writeline(headerfile, "  " + node.name + "Node(" + (", ".join(members)) + ");")
    writeline(headerfile, "};")
    writeline(headerfile, "")

writeline(headerfile, "// Define the provided Print visitor, which will print the AST,")
writeline(headerfile, "//   this is an example of a concrete visitor which visit the tree")
writeline(headerfile, "class Print : public Visitor {")
writeline(headerfile, "private:")
writeline(headerfile, "  std::vector<std::string>* elements;")
writeline(headerfile, "  std::stack<std::vector<std::string>*> stack;")
writeline(headerfile, "  unsigned int indent;")
writeline(headerfile, "")
writeline(headerfile, "  void pushLevel(std::string, bool);")
writeline(headerfile, "  void addElement(std::string);")
writeline(headerfile, "  void popLevel(bool, bool);")
writeline(headerfile, "")
writeline(headerfile, "public:")
for node in nodes:
    writeline(headerfile, "  virtual void visit" + node.name + "Node(" + node.name + "Node* node);")
writeline(headerfile, "  virtual void visitIdentifierNode(IdentifierNode* node);")
writeline(headerfile, "  virtual void visitIntegerNode(IntegerNode* node);")
writeline(headerfile, "};")


writeline(headerfile, "")
writeline(headerfile, "#endif")
writeline(headerfile, "")

# Close header file
headerfile.close()

# Output the code file (refer to inline C comments for meaning of C code)
writeline(codefile, "#include \"" + headerfilename + "\"")
writeline(codefile, "// For node constructors, all children are taken as")
writeline(codefile, "//   parameters, and must be passed in. Optional children")
writeline(codefile, "//   may be NULL pointers. List children are pointers to")
writeline(codefile, "//    std::lists of the appropriate type (pointer to some node type).")
for node in nodes:
    writeline(codefile, "")
    writeline(codefile, "// Visit Children method for " + node.name + " AST node")
    writeline(codefile, "void " + node.name + "Node::visit_children(Visitor* v) {")
    dupnames = {}
    childnames = []
    members = []
    
    for child in node.children:
        if (child.name in childnames):
            dupnames[child.name] = 1
        else:
            childnames.append(child.name)
    for child in node.children:
        number = ""
        if (child.name in dupnames.keys()):
            number = "_" + str(dupnames[child.name])
            dupnames[child.name] = dupnames[child.name] + 1
        
        if (child.list):
            writeline(codefile, "  if (this->" + child.name.lower() + "_list" + number + ") {")
            writeline(codefile, "    for(std::list<" + child.name + "Node*" + ">::iterator iter = this->" + child.name.lower() + "_list" + number + "->begin();")
            writeline(codefile, "        iter != this->" + child.name.lower() + "_list" + number + "->end(); iter++) {")
            writeline(codefile, "      (*iter)->accept(v);")
            writeline(codefile, "    }")
            writeline(codefile, "  }")
            members.append(("std::list<" + child.name + "Node*" + ">*", child.name.lower() + "_list" + number))
        elif (child.optional):
            writeline(codefile, "  if (this->" + child.name.lower() + number + ") {")
            writeline(codefile, "    this->" + child.name.lower() + number + "->accept(v);")
            writeline(codefile, "  }")
            members.append((child.name + "Node* ", child.name.lower() + number))
        else:
            writeline(codefile, "  " + child.name.lower() + number + "->accept(v);")
            members.append((child.name + "Node* ", child.name.lower() + number))
    writeline(codefile, "}")
    
    if (len(members) > 0):
        writeline(codefile, "")
        writeline(codefile, "// Constructor for " + node.name + " AST node")
        writeline(codefile, "" + node.name + "Node::" + node.name + "Node(" + (", ".join(map(lambda x: x[0] + " " + x[1], members))) + ") {")
        for member in members:
            writeline(codefile, "  this->" + member[1] + " = " + member[1] + ";")
        writeline(codefile, "}")

writeline(codefile, "")
writeline(codefile, "// Definitions for print functions")
writeline(codefile, "// Push Level adds a new level to the printed tree (for a node with children)")
writeline(codefile, "void Print::pushLevel(std::string name, bool indent = false) {")
writeline(codefile, "  if (this->elements)")
writeline(codefile, "    this->stack.push(this->elements);")
writeline(codefile, "  this->elements = new std::vector<std::string>();")
writeline(codefile, "  std::stringstream ss;")
writeline(codefile, "  if (indent)")
writeline(codefile, "    this->indent += 1;")
writeline(codefile, "  ss << name << \"(\";")
writeline(codefile, "  this->elements->push_back(ss.str());")
writeline(codefile, "}")
writeline(codefile, "")
writeline(codefile, "// Add Element adds a new leaf to the printed tree (for a node with no children)")
writeline(codefile, "void Print::addElement(std::string name) {")
writeline(codefile, "  this->elements->push_back(name);")
writeline(codefile, "}")
writeline(codefile, "")
writeline(codefile, "// Pop Level finishes the printing of a node with children, and matches with")
writeline(codefile, "//   calls to push level.")
writeline(codefile, "void Print::popLevel(bool breaklines = false, bool deindent = false) {")
writeline(codefile, "  std::stringstream ss;")
writeline(codefile, "  ss << this->elements->at(0);")
writeline(codefile, "  if (breaklines) {")
writeline(codefile, "    ss << \"\\n\";")
writeline(codefile, "    for (int i = 0; i < this->indent; i++)")
writeline(codefile, "      ss << \" \";")
writeline(codefile, "  }")
writeline(codefile, "  for (std::vector<std::string>::iterator iter = this->elements->begin()+1; iter != this->elements->end(); iter++) {")
writeline(codefile, "    ss << (*iter);")
writeline(codefile, "    if (iter != this->elements->end() - 1) {")
writeline(codefile, "      ss << \",\";")
writeline(codefile, "      if (breaklines) {")
writeline(codefile, "        ss << \"\\n\";")
writeline(codefile, "        for (int i = 0; i < this->indent; i++)")
writeline(codefile, "          ss << \" \";")
writeline(codefile, "      } else {")
writeline(codefile, "        ss << \" \";")
writeline(codefile, "      }")
writeline(codefile, "    } else {")
writeline(codefile, "      if (breaklines) {")
writeline(codefile, "        if (deindent)")
writeline(codefile, "          this->indent -= 1;")
writeline(codefile, "        ss << \"\\n\";")
writeline(codefile, "        for (int i = 0; i < this->indent; i++)")
writeline(codefile, "          ss << \" \";")
writeline(codefile, "      }")
writeline(codefile, "    }")
writeline(codefile, "  }")
writeline(codefile, "  delete this->elements;")
writeline(codefile, "  ss << \")\";")
writeline(codefile, "  if (!stack.empty()) {")
writeline(codefile, "    this->elements = stack.top();")
writeline(codefile, "    this->elements->push_back(ss.str());")
writeline(codefile, "    stack.pop();")
writeline(codefile, "  } else")
writeline(codefile, "    std::cout << ss.str() << std::endl;")
writeline(codefile, "}")
writeline(codefile, "")
writeline(codefile, "// Define concrete implementations of all abstract visitor functions")
for node in nodes:
    writeline(codefile, "// Concrete visit function for " + node.name + " nodes")
    writeline(codefile, "void Print::visit" + node.name + "Node(" + node.name + "Node* node) {")
    if (len(node.children) > 0):
        pushflags = popflags = ""
        if (node.indent):
            pushflags = ", true";
            popflags = "true, true"
        writeline(codefile, "  this->pushLevel(\"" + node.name + "\"" + pushflags + ");")
        writeline(codefile, "  node->visit_children(this);")
        writeline(codefile, "  this->popLevel(" + popflags + ");")
    else:
        writeline(codefile, "this->addElement(\"" + node.name + "\");")
    writeline(codefile, "}")
    writeline(codefile, "")
writeline(codefile, "// Concrete visit function for Identifiers (leaf nodes)")
writeline(codefile, "void Print::visitIdentifierNode(IdentifierNode* node) {")
writeline(codefile, "  std::stringstream ss;")
writeline(codefile, "  // Print the name of the indentifier surrounded by quotes")
writeline(codefile, "  ss << \"\\\"\" << node->name << \"\\\"\";")
writeline(codefile, "  this->addElement(ss.str());")
writeline(codefile, "  node->visit_children(this);")
writeline(codefile, "}")
writeline(codefile, "")
writeline(codefile, "void Print::visitIntegerNode(IntegerNode* node) {")
writeline(codefile, "  std::stringstream ss;")
writeline(codefile, "  // Print the value of the integer")
writeline(codefile, "  ss << node->value;")
writeline(codefile, "  this->addElement(ss.str());")
writeline(codefile, "  node->visit_children(this);")
writeline(codefile, "}")
writeline(codefile, "")

# Close code file
codefile.close()
