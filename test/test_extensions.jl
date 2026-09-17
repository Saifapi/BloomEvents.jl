using Test
using Dates
using NCDatasets
using CairoMakie

@testset "Extensions" begin

    @test Base.get_extension(BloomEvents, :BloomEventsNCDatasetsExt) !== nothing
    @test Base.get_extension(BloomEvents, :BloomEventsCairoMakieExt) !== nothing

end
