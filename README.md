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
let store = PapyrusStore()
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

## Note

Worth noting Papyrus is still in very early days and API's are expected to change dramatically. Saying that, [SEMVER](https://semver.org) will be kept.

## Apps using Papyrus

- [Stocket](https://apps.apple.com/gb/app/stocket-app/id1555942263)

## Documentation

[API Reference](https://mystifying-bohr-b56ce9.netlify.app)

## Usage

All write functions are synchronous and have asynchonous counterparts. Variety is the spice of life after all.  

### Saving

Anything that conforms to the `Papyrus` protocol can be stored.

#### Example A - Basic Saving

```swift
struct Car: Papyrus
{
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = PapyrusStore()
store.save(car)
```

#### Example B - Eventual Saving

```swift
struct Car: Papyrus
{
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = PapyrusStore()
store.saveEventually(car)
```

#### Example C - Relationships

Papyrus also understands relationships. If we continue with our `Car` modelling...Let's imagine we have an app that fetches a list of car manufacturers and their cars.

Our models could look like:

```swift
struct Manufacturer: Papyrus
{
    let id: String
    let name: String
    @HasMany let cars: [Car]
    @HasOne let address: Address
}

struct Car: Papyrus
{
    let id: String
    let model: String
}

struct Address: Papyrus
{
    let id: UUID
    let lineOne: String
    let lineTwo: String?
}

let modelS = Car(id: "abc...", model: "Model S")
let address = Address(id: UUID(), lineOne: "blah blah", lineTwo: nil)
let tesla = Manufacturer(
    id: "abc...", 
    name: "Tesla", 
    cars: [modelS], 
    address: address
)

let store = PapyrusStore()
store.save(tesla)
```

Because `Car` and `Address` also conforms to `Papyrus` and the `@HasMany` and `@HasOne` property wrappers have been used, `PapyrusStore` will also persist the cars and the address when it saves the manufacturer.

#### Example D - Merge

A common use case when dealing with API's is to fetch a collection of objects and the merge the results into your local collection.

Merge also has a async counterpart `mergeEventually(objects:)`.

Papyrus provides a function for this:

```swift
let carA = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let carB = Car(id: "def...", model: "Model 3", manufacturer: "Tesla")
let carC = Car(id: "ghi...", model: "Model X", manufacturer: "Tesla")

let store = PapyrusStore()
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
let store = PapyrusStore()
let tesla = try store.object(id: "abc...", of: Manufacturer.self).execute()
```

#### Example B

You also have the option of a Publisher that will fire an event on first fetch and then when the object changes or is deleted. 

When the object doesn't exist a `PapyrusStore.QueryError` error is sent.

```swift
let store = PapyrusStore()
let cancellable = store.object(id: "abc...", of: Manufacturer.self)
    .publisher()
    .sink(
        receiveCompletion: { ... },
        receiveValue: { ... }
    )
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

Calling `publisher()` on a `PapryrusStore.CollectionQuery` object will return a Combine publisher which will emit the collection of objects. Unless specified the publisher will continue to emit a collection objects whenever a change is detected.

A change constitutes of:

- Addition of an object.
- Deletion of an object.
- Update of an object.

#### Example D - Observing changes

```swift
self.store
    .objects(type: Manufacturer.self)
    .publisher()
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
    .publisher()
    .subscribe(on: DispatchQueue.global())
    .receive(on: DispatchQueue.main)
    .sink { self.updateUI(with: $0) }
    .store(in: &self.cancellables)
```

### Deleting

There are several methods for deleting objects.

#### Example A

```swift
let store = PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
store.delete(tesla)
```

#### Example B

```swift
let store = try PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
store.deleteEventually(tesla)
```

#### Example C

```swift
let store = try PapyrusStore()
store.delete(id: "abc...", of: Manufacturer.self)
```

#### Example D

```swift
let store = try PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
let ford = store.object(id: "xyz...", of: Manufacturer.self)
store.delete(objects: [tesla, ford])
```

## License

Whatevs.
