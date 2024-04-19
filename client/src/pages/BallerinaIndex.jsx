import { gql, useQuery } from "@apollo/client"
import React from "react"


const PLACES = gql`
    query getPlaces{
        places{
            id
            name
            city
            country
        }
    }
`

export default function BallerinaIndex() {
    const { error, loading, data } = useQuery(PLACES)

    // Handle states
    if (error) {
        console.log(error)
        return <h1>Error</h1>
    }
    if (loading) return <h1>Loading...</h1>
    if (!data) return <h1>No data</h1>

    return (
        <div style={{
            display: "flex",
            flexWrap: "wrap",
            justifyContent: "center",
            alignItems: "center",
            gap: "1rem",
            minHeight: "100vh",
        }}>
            {data?.places.map((place, index) => (
                <div
                    key={index}
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        justifyContent: "center",
                        alignItems: "center",
                        width: "fit-content",
                        padding: "1rem",
                        borderRadius: "0.5rem",
                        backgroundColor: "#101010",
                        color: "#ffffff"
                    }}>
                    <h1>{place.name}</h1>
                    <section style={{
                        display: "flex",
                        justifyContent: "center",
                        gap: "0.5rem",
                        alignItems: "center",
                        color: "#ff0055"
                    }}>
                        <p>{place.city}</p>
                        <p>{place.country}</p>
                    </section>
                </div>
            ))}
        </div>
    )
}
