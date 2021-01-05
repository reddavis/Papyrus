# Papyrus

Papyrus aims to hit the sweet spot between saving raw API responses to the file system and a fully fledged database like Realm.

```swift
struct Car: Papyrus
{
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = try PapyrusStore()
store.save(car)
```

## Requirements

- iOS 14.0+
- macOS 11.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/reddavis/Papryrus", from: "0.9.0")
]
```

## Documentation

[API Reference](https://mystifying-bohr-b56ce9.netlify.app)

## Usage

### Saving

Anything that conforms to the `Papyrus` protocol can be stored. When an object is added to the store, it is firstly added to the in-memory cache and then eventually written to the store.

#### Example A - Basic Saving

```swift
struct Car: Papyrus
{
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = try PapyrusStore()
store.save(car)
```

#### Example B - Relationships

Papyrus also understands relationships. If we continue with our `Car` modelling...Let's imagine we have an app that fetches a list of car manufacturers and their cars.

Our models could look like:

```swift
struct Manufacturer: Papyrus
{
    let id: String
    let name: String
    let cars: [Car]
}

struct Car: Papyrus
{
    let id: String
    let model: String
}

let modelS = Car(id: "abc...", model: "Model S")
let tesla = Manufacturer(id: "abc...", name: "Tesla", cars: [modelS])
let store = try PapyrusStore()
store.save(tesla)
```

Because `Car` also conforms to `Papyrus`, `PapyrusStore` will also persist the cars when it saves the manufacturer.

#### Example C - Merge

A common use case when dealing with API's is to fetch a collection of objects and the merge the results into your local collection.

Papyrus provides a function for this:

```swift
let carA = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let carB = Car(id: "def...", model: "Model 3", manufacturer: "Tesla")
let carC = Car(id: "ghi...", model: "Model X", manufacturer: "Tesla")

let store = try PapyrusStore()
store.save(objects: [carA, carB])

store.merge(with: [carA, carC])
store
    .objects(type: Car.self)
    .execute()
// #=> [carA, carC]
```

### Fetching by ID

Fetching objects has two forms:
- Fetch by id.
- Fetch collection.

#### Example A

```swift
let store = try PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
```

### Fetching collections

Papryrus gives you the ability to fetch, filter and observe colletions of objects.

#### Example A - Simple fetch

```swift
let manufacturers = self.store
                        .objects(type: Manufacturer.self)
                        .execute()
```

#### Example B - Filtering

```swift
let manufacturers = self.store
                        .objects(type: Manufacturer.self)
                        .filter { $0.name == "Tesla" }
                        .execute()
```

#### Example C - Sorting

```swift
let manufacturers = self.store
                        .objects(type: Manufacturer.self)
                        .sort { $0.name < $1.name }
                        .execute()
```

Calling `observe()` on a `PapryrusStore.Query` object will return a Combine publicher which will emit the collection of objects. Unless specified the publisher will continue to emit a collection objects whenever a change is detected.

A change constitutes of:

- Addition of an object.
- Deletion of an object.
- Update of an object.

#### Example D - Observing changes

```swift
self.store
    .objects(type: Manufacturer.self)
    .observe()
    .subscribe(on: DispatchQueue.global())
    .receive(on: DispatchQueue.main)
    .sink { self.updateUI(with: $0) }
    .store(in: &self.cancellables)
```
#### Example E - All together

```swift
self.store
    .objects(type: Manufacturer.self)
    .filter { $0.name == "Tesla" }
    .sort { $0.name < $1.name }
    .observe()
    .subscribe(on: DispatchQueue.global())
    .receive(on: DispatchQueue.main)
    .sink { self.updateUI(with: $0) }
    .store(in: &self.cancellables)
```

### Deleting

There are several methods for deleting objects.

#### Example A

```swift
let store = try PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
store.delete(tesla)
```

#### Example B

```swift
let store = try PapyrusStore()
store.delete(id: "abc...", of: Manufacturer.self)
```

#### Example C

```swift
let store = try PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
let ford = store.object(id: "xyz...", of: Manufacturer.self)
store.delete(objects: [tesla, ford])
```

## License

Whatevs.
