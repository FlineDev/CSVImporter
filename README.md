<p align="center">
    <img src="Logo.png" width=600 height=167>
</p>

# CSVImporter

Import CSV files line by line with ease.

## Installation

Currently the recommended way of installing this library is via [Carthage](https://github.com/Carthage/Carthage).
[Cocoapods](https://github.com/CocoaPods/CocoaPods) isn't supported yet (contributions welcome!).

You can of course also just include this framework manually into your project by downloading it or by using git submodules.

### Carthage

Simply add this line to your Cartfile:

```
github "Flinesoft/CSVImporter"
```

And run `carthage update`. Then drag & drop the HandySwift.framework in the Carthage/build folder to your project. Also do the same with the dependent frameworks `Filekit` and `HandySwift`. Now you can `import CSVImporter` in each class you want to use its features.

## Usage

First create an instance of CSVImporter and specify the type the data within a line from the CSV should have. The default data type is an array of `String` objects which would look like this:

``` Swift
let path = "path/to/your/CSV/file"
let importer = CSVImporter<[String]>(path: path)
importer.startImportingRecords{ $0 }.onFinish { importedRecords in
    for record in importedRecords {
        // record is of type [String] and contains all data in a line
    }
}
```

CSVImporter works completely asynchronous and therefore doesn't block the main thread. As you can see the `onFinish` method is called once it finishes for using the results. There is also `onFail` for failure cases (for example when the given path doesn't contain a CSV file), `onProgress` which is regularly called and provides the number of lines already processed (e.g. for progress indicators). You can chain them as follows:

``` Swift
importer.startImportingRecords{ $0 }.onFail {

    print("The CSV file couldn't be read.")

}.onProgress { importedDataLinesCount in

    print("\(importedDataLinesCount) lines were already imported.")

}.onFinish { importedRecords in

    print("Did finish import with \(importedRecords.count) records.")

}
```

As stated above the default type is a `[String]` but you can provide whatever type you like. For example, let's say you have a class like this

``` Swift
class Student {
  let firstName: String, lastName: String
  init(firstName: String, lastName: String) {
    self.firstName = firstName
    self.lastName = lastName
  }
}
```

and your CSV file looks something like the following

``` CSV
Harry,Potter
Hermione,Granger
Ron,Weasley
```

then you can specify a mapper as the closure instead of the `{ $0 }` from the examples above like this:

``` Swift
let path = "path/to/Hogwarts/students"
let importer = CSVImporter<Student>(path: path)
importer.startImportingRecords { recordValues -> Student in

    return Student(firstName: recordValues[0], lastName: recordValues[1])

}.onFinish { importedRecords in

    for student in importedRecords {
        // Now importedRecords is an array of Students
    }

}
```

Last but not least some CSV files have the structure of the data specified within the first line like this:

``` CSV
firstName,lastName
Harry,Potter
Hermione,Granger
Ron,Weasley
```

In that case CSVImporter can automatically provide each record as a dictionary like this:

``` Swift
let path = "path/to/Hogwarts/students"
let importer = CSVImporter<[String: String]>(path: path)
importer.startImportingRecords(structure: { (headerValues) -> Void in

    print(headerValues) // => ["firstName", "lastName"]

}){ $0 }.onFinish { importedRecords in

    for record in importedRecords {
        print(record) // => e.g. ["firstName": "Harry", "lastName": "Potter"]
        print(record["firstName"]) // prints "Harry" on first, "Hermione" on second run
        print(record["lastName"]) // prints "Potter" on first, "Granger" on second run
    }

}
```

Note: If a records values count doesn't match that of the first lines values count then the record will be ignored.


## Contributing

Contributions are welcome. Please just open an Issue on GitHub to discuss a point or request a feature or send a Pull Request with your suggestion.

Pull requests with new features will only be accepted when the following are given:
- **Tests** for the new feature exist and all tests pass successfully for all targets.

## License
This library is released under the [MIT License](http://opensource.org/licenses/MIT). See LICENSE for details.
