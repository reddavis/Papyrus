# Papyrus

Papyrus enables offline first applications by providing a simple object cache layer.

## Simple example

```swift
struct Car: Papyrus {
    let id: String
    let model: String
    let manufacturer: String
}

let car = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let store = PapyrusStore()
try await store.save(car)
```

## Realworld example

In this example, we're using a `AsyncThrowingStream` to pump through values.

The general concept is that firstly we yield the cached data, perform the API request, yield the new objects and finally 
merge the new cached objects.

```swift
import AsyncAlgorithms
import Papyrus

struct CarProvider {
    var all: () -> AsyncThrowingStream<[Car], Error>
}

extension CarProvider {
    static func live(
        apiClient: TeslaAPIClient = .live,
        store: PapyrusStore = .live
    ) -> Self {
        .init(
            all: {
                AsyncThrowingStream { continuation in
                    do {
                        var stores = store.objects(type: Car.self).execute()
                        continuation.yield(stores)
                        
                        let request = FetchCarsRequest()
                        cars = try await apiClient.execute(request: request)
                        continuation.yield(cars)
                        try await store.merge(with: cars)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                .removeDuplicates()
                .eraseToThrowingStream()
            }
        )
    }
}
```

## Requirements

- iOS 15.0+
- macOS 12.0+
- watchOS 6.0+
- tvOS 15.0+

## Installation

### Swift Package Manager

In Xcode:

1. Click `Project`.
2. Click `Package Dependencies`.
3. Click `+`.
4. Enter package URL: `https://github.com/reddavis/Papyrus`.
5. Add `Papyrus` to your app target.

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
try await store.save(car)
```

#### Example B - Merge

A common use case when dealing with API's is to fetch a collection of objects and the merge the results into your local collection.

Papyrus provides a function for this:

```swift
let carA = Car(id: "abc...", model: "Model S", manufacturer: "Tesla")
let carB = Car(id: "def...", model: "Model 3", manufacturer: "Tesla")
let carC = Car(id: "ghi...", model: "Model X", manufacturer: "Tesla")

let store = PapyrusStore()
try await store.save(objects: [carA, carB])

try await store.merge(with: [carA, carC])
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
let tesla = store.object(id: "abc...", of: Manufacturer.self).execute()
```

#### Example B

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
let manufacturers = self.store
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

#### Example D - Observing changes

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
try store.delete(tesla)
```

#### Example B

```swift
let store = PapyrusStore()
try store.delete(id: "abc...", of: Manufacturer.self)
```

#### Example C

```swift
let store = PapyrusStore()
let tesla = store.object(id: "abc...", of: Manufacturer.self)
let ford = store.object(id: "xyz...", of: Manufacturer.self)
try store.delete(objects: [tesla, ford])
```
