{-# LANGUAGE DeriveFunctor #-}

-- https://adventofcode.com/2019/day/6

import qualified Data.Map.Strict as Map
import Recursion


-- OrbitData maps each object to the list of objects directly orbiting it
type OrbitData = Map.Map String [String]

-- split a string "foo)bar" into a tuple containing the substrings "foo" and "bar"
get_names str = (a, tail b)
    where
        (a, b) = break (== ')') str

-- add `v` to the list of values associated with key `k`
append m (k, v) = Map.alter update k m
    where
        update Nothing   = Just [v]
        update (Just vs) = Just $ v:vs

-- parse one orbit relation per line and collect them in a multi-map
parse :: String -> OrbitData
parse = foldl append Map.empty . map get_names . lines


-- Recursive tree for unfolding orbit data
data TreeF a = NodeF String [a] deriving Functor

type Tree = Fix TreeF

orbits :: OrbitData -> Coalgebra TreeF String
orbits od o =
  case Map.lookup o od of
    Nothing -> NodeF o []
    Just ps -> NodeF o ps


-- Part 1: Counting direct and indirect orbits
count_orbits :: Algebra TreeF (Int, Int)
count_orbits (NodeF _ [])  = (0,0)
count_orbits (NodeF _ lst) = (direct, indirect)
  where
    direct       = length lst + rec_direct
    indirect     = rec_direct + rec_indirect
    rec_direct   = sum $ map fst lst
    rec_indirect = sum $ map snd lst


-- Part 2: Counting necessary orbit transfers
data Distance = DistZero | DistOne Int | DistTwo Int deriving Show

count_transfers :: Algebra TreeF Distance
count_transfers (NodeF "YOU" []) = DistOne 0
count_transfers (NodeF "SAN" []) = DistOne 0
count_transfers (NodeF _     []) = DistZero
count_transfers (NodeF _ lst)    = update $ foldl combine DistZero lst
  where
    combine DistZero x = x
    combine (DistOne n) (DistOne m) = DistTwo (n + m)
    combine x _     = x

    update (DistOne n) = DistOne (n+1)
    update x = x


main = do
  od <- parse <$> readFile ("day_6_input.txt")
  putStrLn $ "Part 1: " ++ (show $ hylo count_orbits (orbits od) "COM")
  putStrLn $ "Part 2: " ++ (show $ hylo count_transfers (orbits od) "COM")
