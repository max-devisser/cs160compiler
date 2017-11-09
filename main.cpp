#include "ast.hpp"
#include "parser.hpp"

extern int yydebug;
extern int yyparse();
extern int yylex (void);

ASTNode* astRoot;

int main(int argc, char **argv) {
  yydebug = (argc == 2 && argv[1] == std::string("-d")) ? 1 : 0;
  
  if (argc == 2 && argv[1] == std::string("-s")) {
    int t;
    while ((t = yylex())) std::cout << t << std::endl;
      return 0;
  }

  yyparse();
  
  if (astRoot) {
    Print* printer = new Print();
    astRoot->accept(printer);
  }

  return 0;
}
