name import

description "This is the heart of everything."

version "$( grep IMPORT_VERSION= import.sh | sed "s/.*\([0-9]\.[0-9]\.[0-9]\).*/\1/" )"

exclude spec/
