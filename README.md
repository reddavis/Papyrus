# Papyrus

Papyrus aims to hit the sweet spot between saving raw API responses to the file system and a fully fledged database like Realm.

```swift
struct Car: Papyrus {
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = PapyrusStore()
await store.save(car)
```

## Requirements

- iOS 15.0+
- macOS 12.0+

## Installation

### Swift Package Manager

In Xcode:

1. Click `Project`.
2. Click `Package Dependencies`.
3. Click `+`.
4. Enter package URL: `https://github.com/reddavis/Papyrus`.
5. Add `Papyrus` to your app target.

## Apps using Papyrus

- [Stocket](https://apps.apple.com/gb/app/stocket-app/id1555942263)

## Documentation

[API Reference](https://mystifying-bohr-b56ce9.netlify.app)

## Usage  

### Saving

Anything that conforms to the `Papyrus` protocol can be stored.

The `Papyrus` protocol is simply an umbrella of these three protocols:

- `Codable`
- `Equatable`
- `Identifiable where ID: LosslessStringConvertible`

#### Example A 

```swift
struct Car: Papyrus {
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = PapyrusStore()
await store.save(car)
```

#### Example B - Relationships

Papyrus also understands relationships. If we continue with our `Car` modelling...Let's imagine we have an app that fetches a list of car manufacturers and their cars.

Our models could look like:

```swift
struct Manufacturer: Papyrus {
    let id: String
    let name: String
    @HasMany let cars: [Car]
    @HasOne let address: Address
}

struct Car: Papyrus {
    let id: String
    let model: String
}

struct Address: Papyrus {
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
await store.save(tesla)
```

Because `Car` and `Address` also conforms to `Papyrus` and the `@HasMany` and `@HasOne` property wrappers have been used, `PapyrusStore` will also persist the cars and the address when it saves the manufacturer. This means that we are able to perform direct queries on `Car`'s and `Address`es. 

#### Example C - Merge

A common use case when dealing with API's is to fetch a collection of objects and the merge the results into your local collection.

Papyrus provides a function for this:

```swift
let carA = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let carB = Car(id: "def...", model: "Model 3", manufacturer: "Tesla")
let carC = Car(id: "ghi...", model: "Model X", manufacturer: "Tesla")

let store = PapyrusStore()
store.save(objects: [carA, carB])

await store.merge(with: [carA, carC])
await store
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
let tesla = try await store.object(id: "abc...", of: Manufacturer.self).execute()
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

#### Example C

With Swift 5.5 came async/await, which also introduced `AsyncSequence`. 

When the object doesn't exist a `PapyrusStore.QueryError` error is thrown.

```swift
let store = PapyrusStore()
let stream = store.object(id: "abc...", of: Manufacturer.self).stream()

do {
    for try await object in stream {
        ...
    }
} catch {
    //.. Do something
}

```

### Fetching collections

Papryrus gives you the ability to fetch, filter and observe colletions of objects.

#### Example A - Simple fetch

```swift
let manufacturers = await self.store
    .objects(type: Manufacturer.self)
    .execute()
```

#### Example B - Filtering

```swift
let manufacturers = await self.store
    .objects(type: Manufacturer.self)
    .filter { $0.name == "Tesla" }
    .execute()
```

#### Example C - Sorting

```swift
let manufacturers = await self.store
    .objects(type: Manufacturer.self)
    .sort { $0.name < $1.name }
    .execute()
```

#### Example D - Observing changes with Combine

Calling `publisher()` on a `PapryrusStore.CollectionQuery` object will return a Combine publisher which will emit the collection of objects. Unless specified the publisher will continue to emit a collection objects whenever a change is detected.

A change constitutes of:

- Addition of an object.
- Deletion of an object.
- Update of an object.

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

#### Example F - Observing changes with a stream

Calling `stream()` on a `PapryrusStore.CollectionQuery` object will return a `AsyncThrowingStream` which will emit the collection of objects. Unless specified the stream will continue to emit a collection objects whenever a change is detected.

A change constitutes of:

- Addition of an object.
- Deletion of an object.
- Update of an object.

```swift
let stream = self.store
    .objects(type: Manufacturer.self)
    .filter { $0.name == "Tesla" }
    .sort { $0.name < $1.name }
    .stream()

do {
    for try await manufacturers in stream {
        // ... Do something with [Manufacturer].
    }
} catch {
    //.. Do something
}

```

### Deleting

There are several methods for deleting objects.

#### Example A

```swift
let store = PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
await store.delete(tesla)
```

#### Example B

```swift
let store = PapyrusStore()
await store.delete(id: "abc...", of: Manufacturer.self)
```

#### Example C

```swift
let store = PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
let ford = store.object(id: "xyz...", of: Manufacturer.self)
await store.delete(objects: [tesla, ford])
```

### Migrations (experimental)

If the wish is to keep existing data when introducing schema changes you can register a migration.

#### Example A

```swift
struct Car: Papyrus {
    let id: String
    let model: String
    let manufacturer: String
}

struct CarV2: Papyrus {
    let id: String
    let model: String
    let manufacturer: String
    let year: Int
}

let migration = Migration<Car, CarV2> { oldObject in
    CarV2(
        id: oldObject.id,
        model: oldObject.model,
        manufacturer: oldObject.manufacturer,
        year: 0
    )
}

await self.store.register(migration: migration)
```

## License

Whatevs.
