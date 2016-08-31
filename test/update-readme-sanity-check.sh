#!/bin/sh

test_folder='shared/src/test/scala/fr/hmil/roshttp'
test_name='ReadmeSanityCheck'
fatalDiff='no'
if [ "$1" = "--fatalDiff" ]; then
  fatalDiff='yes'
fi

# Filters lines from the README to output only lines of code enclosed by scala markdown code tags
filter_code() {
  awk '/```/{e=0}/^```scala/{gsub("^```scala","",$0);e=1}{if(e==1){print}}'
}

format_code() {
  cat <<EOF
package fr.hmil.roshttp

import utest._

object $test_name extends TestSuite {
  // Shims libraryDependencies
  class Dep {
    def %%%(s: String): String = "%%%"
    def %%(s: String): String = "%%"
    def %(s: String): String = "%"
  }
  implicit def fromString(s: String): Dep = new Dep()
  var libraryDependencies = Set[Dep]()
  
  // Silence print output
  def println(s: String): Unit = ()
  
  // Test suite
  val tests = this {
    "Readme snippets compile and run successfully" - {
EOF
  # print raw code in test suite
  sed -rn 's/^(.*)$/      \1/p'
  cat <<EOF
  
      "Success"
    }
  }
}
EOF
}

update_sanity_check() {
  cat README.md | filter_code | format_code > $test_folder/$test_name.scala
}

echo "Verifying readme sanity check..."
mv $test_folder/$test_name.scala $test_folder/$test_name.old
update_sanity_check
diff $test_folder/$test_name.scala $test_folder/$test_name.old
status="$?"
rm $test_folder/$test_name.old
if [ ! "$status" -eq 0 ]; then
  if [ "$fatalDiff" = "yes" ]; then
    cat <<EOF
ERROR: Readme sanity check file is out of sync
Snippets of code in the readme have been updated. Please run $0 to regenerate the README sanity check file.
EOF
    exit 1
  else
    echo "Readme sanity check has been updated"
  fi
else
  echo "Readme sanity check is up to date."
fi

exit 0