from subprocess import Popen, PIPE
from os import listdir, path
from functools import total_ordering
from sys import argv

@total_ordering
class NameOrder(object):
	def __init__(self, value):
		self.value = value
	def __eq__(self, other):
		return self.value == other.value
	def __lt__(self, other):
		firstNumber, sep, firstEnding = self.value.partition(".")
		firstNumber = firstNumber.partition("/")[2]
		secondNumber, sep, secondEnding = other.value.partition(".")
		secondNumber = secondNumber.partition("/")[2]
		if (firstEnding != secondEnding):
			return firstEnding > secondEnding
		else:
			return int(firstNumber) < int(secondNumber)

def runTests(verbose):
	if (not path.isdir("tests/")):
		print("No tests directory.")
		return
	files = sorted(["tests/" + f for f in listdir('tests') if path.isfile("tests/" + f) and f.endswith(".lang")], key=NameOrder)

	for f in files:
		infile = open(f, 'r')

		print("./lang < " + f + ":")
		p = Popen(["./lang"], stdin=infile, stdout=PIPE, stderr=PIPE)
		(out, err) = p.communicate()

		try:
			if (verbose):
				if (out):
					print(out.decode("utf-8"))
				if (err):
					print(err.decode("utf-8"))
				elif (not out):
					print("No output.\n")
			else:
				if (out):
					print(out.decode("utf-8"))
				if (err):
					if (len(err.decode("utf-8").strip().split("\n")) > 1):
						print("Multiple errors produced.\n")
					else:
						line = err.decode("utf-8").strip().split()[-1]
						print("Error produced on line " + line + ".\n")
				elif (not out):
					print("No output.\n")
		
		except UnicodeDecodeError:
			print("Invalid characters in output.\n")

def main():
	if (len(argv) > 1 and argv[1] == "-v"):
		runTests(True)
	else:
		runTests(False)

if __name__ == "__main__":
	main()
