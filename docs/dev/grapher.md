# Grapher

## Outline of Adding a New Graph Type

This is a quick write up as I commit a new graph type. To be fleshed out.

Our new graphing backend, [Grapher](../features/grapher.md), supports different graph types from different backends. To add a new graph type - let's call it `Example` - you need to do the following:

1. Create a graph class for this new type called `app/Services/Grapher/Graph/Example.php`. This must extend the abstract class `app/Services/Grapher/Graph.php`.
2. Add an `example()` function to `app/Services/Grapher.php` which instantiates the above graph object.
3. Update the appropriate backend file(s) (`app/Services/Grapher/Backend/xxx`) to handle this new graph file. I.e. create the actual implementation for getting the data to process this graph.
4. Add your graph to the `supports()` function in the appropriate backends (and the `app/Services/Grapher/Backend/Dummy` backend).
5. To serve this graph over HTTP:

   1. Create a GET route in `app/Providers/GrapherServiceProvider.php`
   2. Create a function to handle the GET request in `app/Http/Controllers/Services/Grapher.php`
   3. Add functionality to the middleware to process a graph request: `app/Http/Middleware/Services/Grapher.php`

 Here's a great example from a [Github commit](https://github.com/inex/IXP-Manager/commit/a05a598135d023a726efcf62dac852e794792f3c).

## Adding a New MRTG Graph

Here is an example of adding [broadcast graphs](https://github.com/inex/IXP-Manager/commit/7bfffaa04bbca835759d7f65b3976cddd908ecd7#diff-c6d49ecf9afd38d2ecf83672196a0fc9) to MRTG.
