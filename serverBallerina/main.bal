import ballerina/graphql;
import ballerina/http;
import ballerina/log;
import ballerinax/jaeger as _;
import ballerinax/prometheus as _;

import xlibb/pubsub;

final http:Client geoClient = check new ("https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets");

final pubsub:PubSub subscriptions = new;

service class Author {
    final int id;
    final string username;

    function init(@graphql:ID int id) {
        self.id = id;
        self.username = authors.get(id).username;
    }

    resource function get id() returns @graphql:ID int => self.id;

    resource function get username() returns string {
        return self.username;
    }

    resource function get reviews() returns Review[] {
        return from ReviewData reviewData in reviews
            where reviewData.authorId == self.id
            select new Review(reviewData.id);
    }
};

type Place distinct service object {

    resource function get id() returns @graphql:ID int;

    resource function get name() returns string;

    resource function get city() returns string;

    resource function get country() returns string;

    resource function get population() returns int|error;

    resource function get timezone() returns string|error?;

    resource function get reviews() returns Review[];
};

// As union
// type Place PlaceWithEntranceFee|PlaceWithFreeEntrance;

distinct service class PlaceWithEntranceFee {
    *Place;

    final int id;
    final string name;
    final string city;
    final string country;
    final decimal entryFee;

    function init(@graphql:ID int id) {
        self.id = id;
        PlaceData {name, city, country, entryFee} = places.get(id);
        self.name = name;
        self.city = city;
        self.country = country;
        self.entryFee = entryFee;
    }

    resource function get id() returns @graphql:ID int => self.id;

    resource function get name() returns string => self.name;

    resource function get city() returns string => self.city;

    resource function get country() returns string => self.country;

    resource function get fee() returns decimal => self.entryFee;

    // no nil in return type
    resource function get population() returns int|error {
        PopulationData populationData = check getPopulationData(self.city, self.country);
        return populationData.results[0].population;
    }

    // nil in return type
    resource function get timezone() returns string|error? {
        PopulationData populationData = check getPopulationData(self.city, self.country);
        return populationData.results[0].timezone;
    }

    resource function get reviews() returns Review[] {
        return from ReviewData reviewData in reviews
            where reviewData.placeId == self.id
            select new Review(reviewData.id);
    }
};

distinct service class PlaceWithFreeEntrance {
    *Place;

    final int id;
    final string name;
    final string city;
    final string country;

    function init(@graphql:ID int id) {
        self.id = id;
        PlaceData {name, city, country} = places.get(id);
        self.name = name;
        self.city = city;
        self.country = country;
    }

    resource function get id() returns @graphql:ID int => self.id;

    resource function get name() returns string => self.name;

    resource function get city() returns string => self.city;

    resource function get country() returns string => self.country;

    // no nil in return type
    resource function get population() returns int|error {
        PopulationData populationData = check getPopulationData(self.city, self.country);
        return populationData.results[0].population;
    }

    // nil in return type
    resource function get timezone() returns string|error? {
        PopulationData populationData = check getPopulationData(self.city, self.country);
        return populationData.results[0].timezone;
    }

    resource function get reviews() returns Review[] {
        return from ReviewData reviewData in reviews
            where reviewData.placeId == self.id
            select new Review(reviewData.id);
    }
};

type ReviewInput record {|
    string content;
    int placeId;
    int authorId;
|};

service class Review {
    final int id;
    final string content;
    final int placeId;
    final int authorId;

    function init(@graphql:ID int id) {
        self.id = id;
        ReviewData {content, authorId, placeId} = reviews.get(id);
        self.content = content;
        self.authorId = authorId;
        self.placeId = placeId;
    }

    resource function get id() returns @graphql:ID int => self.id;

    resource function get content() returns string {
        return self.content;
    }

    resource function get place() returns Place {
        return getPlace(self.placeId);
    }

    resource function get author() returns Author {
        return new Author(self.authorId);
    }
};

type PlaceData record {|
    readonly int id;
    string name;
    string city;
    string country;
    decimal entryFee;
|};

type ReviewData record {|
    readonly int id;
    string content;
    int placeId;
    int authorId;
|};

type AuthorData record {|
    readonly int id;
    string username;
|};

// In Memory Data
final table<PlaceData> key(id) places = table [
    {id: 8000, name: "AA Tower", city: "Colombo", country: "Sri Lanka", entryFee: 0},
    {id: 8001, name: "Auxa", city: "Miami", country: "United States", entryFee: 10},
    {id: 8002, name: "Auxa", city: "Miami", country: "US", entryFee: 10}
];

final table<ReviewData> key(id) reviews = table [
    {id: 1001, placeId: 8000, authorId: 5001, content: "Wonderful place, would recommend!"},
    {id: 1002, placeId: 8001, authorId: 5001, content: "Long queues, not worth the wait."},
    {id: 1003, placeId: 8000, authorId: 5002, content: "Tends to get crowded in the evening, other than that, great experience."},
    {id: 1004, placeId: 8001, authorId: 5000, content: "Getting in is a challenge, but if you can sort out transport, a must visit!"},
    {id: 1005, placeId: 8002, authorId: 5000, content: "Would definitely visit again."}
];

final table<AuthorData> key(id) authors = table [
    {id: 5000, username: "John"},
    {id: 5001, username: "Raya"},
    {id: 5002, username: "Liyana"},
    {id: 5003, username: "Shri"}
];

@graphql:ServiceConfig {
    graphiql: {
        enabled: true
    },
    cors: {
        allowOrigins: ["http://localhost:3000"]
    }
}

service /placer on new graphql:Listener(9000) {
    resource function get review(@graphql:ID int reviewId) returns Review {
        return new Review(reviewId);
    }

    resource function get author(@graphql:ID int authorId) returns Author {
        return new Author(authorId);
    }

    resource function get place(@graphql:ID int placeId) returns Place {
        return getPlace(placeId);
    }

    resource function get reviews() returns Review[] {
        return from ReviewData {id} in reviews
            select new Review(id);
    }

    resource function get authors() returns Author[] {
        return from AuthorData {id} in authors
            select new Author(id);
    }

    resource function get places() returns Place[] {
        return from PlaceData {id} in places
            select getPlace(id);
    }

    remote function addReview(ReviewInput reviewInput) returns Review {
        int id = reviews.nextKey();
        ReviewData reviewData = {id, ...reviewInput};
        reviews.add(reviewData);
        pubsub:Error? status = subscriptions.publish(reviewInput.placeId.toString(), id);
        if status is pubsub:Error {
            log:printError("Error publishing review update", data = reviewData);
        }
        return new (id);
    }

    resource function subscribe reviews(int placeId) returns stream<Review, error?>|error {
        stream<int, error?> ids = check subscriptions.subscribe(placeId.toString());
        return from int id in ids
            select new Review(id);
    }
}

type PopulationData record {
    int total_count;
    record {
        int population;
        string timezone;
    }[] results;
};

function getPopulationData(string city, string country) returns PopulationData|error {
    PopulationData populationData = check geoClient->get(
        string `/geonames-all-cities-with-a-population-500/records?refine=name:${
            city}&refine=country:${country}`);

    if populationData.total_count == 0 {
        return error(string `cannot find data for ${city}, ${country}`);
    }
    return populationData;
}

function getPlace(int placeId) returns Place {
    PlaceData {entryFee} = places.get(placeId);
    return entryFee == 0d ?
        new PlaceWithFreeEntrance(placeId) :
        new PlaceWithEntranceFee(placeId);
}
