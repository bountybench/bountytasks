# Licensed under a 3-clause BSD style license - see LICENSE.rst

"""
This module contains a general framework for defining graphs of transformations
between coordinates, suitable for either spatial coordinates or more generalized
coordinate systems.

The fundamental idea is that each class is a node in the transformation graph,
and transitions from one node to another are defined as functions (or methods)
wrapped in transformation objects.

This module also includes more specific transformation classes for
celestial/spatial coordinate frames, generally focused around matrix-style
transformations that are typically how the algorithms are defined.
"""


import heapq
import inspect
import subprocess
from abc import ABCMeta, abstractmethod
from collections import defaultdict
from contextlib import contextmanager, suppress
from inspect import signature
from warnings import warn

import numpy as np

from astropy import units as u
from astropy.utils.exceptions import AstropyWarning

__all__ = [
    "TransformGraph",
    "CoordinateTransform",
    "FunctionTransform",
    "BaseAffineTransform",
    "AffineTransform",
    "StaticMatrixTransform",
    "DynamicMatrixTransform",
    "FunctionTransformWithFiniteDifference",
    "CompositeTransform",
]


def frame_attrs_from_set(frame_set):
    """
    A `dict` of all the attributes of all frame classes in this
    `~astropy.coordinates.TransformGraph`.

    Broken out of the class so this can be called on a temporary frame set to
    validate new additions to the transform graph before actually adding them.
    """
    result = {}

    for frame_cls in frame_set:
        result.update(frame_cls.frame_attributes)

    return result


def frame_comps_from_set(frame_set):
    """
    A `set` of all component names every defined within any frame class in
    this `~astropy.coordinates.TransformGraph`.

    Broken out of the class so this can be called on a temporary frame set to
    validate new additions to the transform graph before actually adding them.
    """
    result = set()

    for frame_cls in frame_set:
        rep_info = frame_cls._frame_specific_representation_info
        for mappings in rep_info.values():
            for rep_map in mappings:
                result.update([rep_map.framename])

    return result


class TransformGraph:
    """
    A graph representing the paths between coordinate frames.
    """

    def __init__(self):
        self._graph = defaultdict(dict)
        self.invalidate_cache()  # generates cache entries

    @property
    def _cached_names(self):
        if self._cached_names_dct is None:
            self._cached_names_dct = dct = {}
            for c in self.frame_set:
                nm = getattr(c, "name", None)
                if nm is not None:
                    if not isinstance(nm, list):
                        nm = [nm]
                    for name in nm:
                        dct[name] = c

        return self._cached_names_dct

    @property
    def frame_set(self):
        """
        A `set` of all the frame classes present in this TransformGraph.
        """
        if self._cached_frame_set is None:
            self._cached_frame_set = set()
            for a in self._graph:
                self._cached_frame_set.add(a)
                for b in self._graph[a]:
                    self._cached_frame_set.add(b)

        return self._cached_frame_set.copy()

    @property
    def frame_attributes(self):
        """
        A `dict` of all the attributes of all frame classes in this TransformGraph.
        """
        if self._cached_frame_attributes is None:
            self._cached_frame_attributes = frame_attrs_from_set(self.frame_set)

        return self._cached_frame_attributes

    @property
    def frame_component_names(self):
        """
        A `set` of all component names every defined within any frame class in
        this TransformGraph.
        """
        if self._cached_component_names is None:
            self._cached_component_names = frame_comps_from_set(self.frame_set)

        return self._cached_component_names

    def invalidate_cache(self):
        """
        Invalidates the cache that stores optimizations for traversing the
        transform graph.  This is called automatically when transforms
        are added or removed, but will need to be called manually if
        weights on transforms are modified inplace.
        """
        self._cached_names_dct = None
        self._cached_frame_set = None
        self._cached_frame_attributes = None
        self._cached_component_names = None
        self._shortestpaths = {}
        self._composite_cache = {}

    def add_transform(self, fromsys, tosys, transform):
        """Add a new coordinate transformation to the graph.

        Parameters
        ----------
        fromsys : class
            The coordinate frame class to start from.
        tosys : class
            The coordinate frame class to transform into.
        transform : `~astropy.coordinates.CoordinateTransform`
            The transformation object. Typically a
            `~astropy.coordinates.CoordinateTransform` object, although it may
            be some other callable that is called with the same signature.

        Raises
        ------
        TypeError
            If ``fromsys`` or ``tosys`` are not classes or ``transform`` is
            not callable.

        """
        if not inspect.isclass(fromsys):
            raise TypeError("fromsys must be a class")
        if not inspect.isclass(tosys):
            raise TypeError("tosys must be a class")
        if not callable(transform):
            raise TypeError("transform must be callable")

        frame_set = self.frame_set.copy()
        frame_set.add(fromsys)
        frame_set.add(tosys)

        # Now we check to see if any attributes on the proposed frames override
        # *any* component names, which we can't allow for some of the logic in
        # the SkyCoord initializer to work
        attrs = set(frame_attrs_from_set(frame_set).keys())
        comps = frame_comps_from_set(frame_set)

        invalid_attrs = attrs.intersection(comps)
        if invalid_attrs:
            invalid_frames = set()
            for attr in invalid_attrs:
                if attr in fromsys.frame_attributes:
                    invalid_frames.update([fromsys])

                if attr in tosys.frame_attributes:
                    invalid_frames.update([tosys])

            raise ValueError(
                f"Frame(s) {list(invalid_frames)} contain invalid attribute names:"
                f" {invalid_attrs}\nFrame attributes can not conflict with *any* of"
                " the frame data component names (see"
                " `frame_transform_graph.frame_component_names`)."
            )

        self._graph[fromsys][tosys] = transform
        self.invalidate_cache()

    def remove_transform(self, fromsys, tosys, transform):
        """
        Removes a coordinate transform from the graph.

        Parameters
        ----------
        fromsys : class or None
            The coordinate frame *class* to start from. If `None`,
            ``transform`` will be searched for and removed (``tosys`` must
            also be `None`).
        tosys : class or None
            The coordinate frame *class* to transform into. If `None`,
            ``transform`` will be searched for and removed (``fromsys`` must
            also be `None`).
        transform : callable or None
            The transformation object to be removed or `None`.  If `None`
            and ``tosys`` and ``fromsys`` are supplied, there will be no
            check to ensure the correct object is removed.
        """
        if fromsys is None or tosys is None:
            if not (tosys is None and fromsys is None):
                raise ValueError("fromsys and tosys must both be None if either are")
            if transform is None:
                raise ValueError("cannot give all Nones to remove_transform")

            # search for the requested transform by brute force and remove it
            for a in self._graph:
                agraph = self._graph[a]
                for b in agraph:
                    if agraph[b] is transform:
                        del agraph[b]
                        fromsys = a
                        break

                # If the transform was found, need to break out of the outer for loop too
                if fromsys:
                    break
            else:
                raise ValueError(f"Could not find transform {transform} in the graph")

        else:
            if transform is None:
                self._graph[fromsys].pop(tosys, None)
            else:
                curr = self._graph[fromsys].get(tosys, None)
                if curr is transform:
                    self._graph[fromsys].pop(tosys)
                else:
                    raise ValueError(
                        f"Current transform from {fromsys} to {tosys} is not"
                        f" {transform}"
                    )

        # Remove the subgraph if it is now empty
        if self._graph[fromsys] == {}:
            self._graph.pop(fromsys)

        self.invalidate_cache()

    def find_shortest_path(self, fromsys, tosys):
        """
        Computes the shortest distance along the transform graph from
        one system to another.

        Parameters
        ----------
        fromsys : class
            The coordinate frame class to start from.
        tosys : class
            The coordinate frame class to transform into.

        Returns
        -------
        path : list of class or None
            The path from ``fromsys`` to ``tosys`` as an in-order sequence
            of classes.  This list includes *both* ``fromsys`` and
            ``tosys``. Is `None` if there is no possible path.
        distance : float or int
            The total distance/priority from ``fromsys`` to ``tosys``.  If
            priorities are not set this is the number of transforms
            needed. Is ``inf`` if there is no possible path.
        """
        inf = float("inf")

        # special-case the 0 or 1-path
        if tosys is fromsys:
            if tosys not in self._graph[fromsys]:
                # Means there's no transform necessary to go from it to itself.
                return [tosys], 0
        if tosys in self._graph[fromsys]:
            # this will also catch the case where tosys is fromsys, but has
            # a defined transform.
            t = self._graph[fromsys][tosys]
            return [fromsys, tosys], float(t.priority if hasattr(t, "priority") else 1)

        # otherwise, need to construct the path:

        if fromsys in self._shortestpaths:
            # already have a cached result
            fpaths = self._shortestpaths[fromsys]
            if tosys in fpaths:
                return fpaths[tosys]
            else:
                return None, inf

        # use Dijkstra's algorithm to find shortest path in all other cases

        nodes = []
        # first make the list of nodes
        for a in self._graph:
            if a not in nodes:
                nodes.append(a)
            for b in self._graph[a]:
                if b not in nodes:
                    nodes.append(b)

        if fromsys not in nodes or tosys not in nodes:
            # fromsys or tosys are isolated or not registered, so there's
            # certainly no way to get from one to the other
            return None, inf

        edgeweights = {}
        # construct another graph that is a dict of dicts of priorities
        # (used as edge weights in Dijkstra's algorithm)
        for a in self._graph:
            edgeweights[a] = aew = {}
            agraph = self._graph[a]
            for b in agraph:
                aew[b] = float(getattr(agraph[b], "priority", 1))

        # entries in q are [distance, count, nodeobj, pathlist]
        # count is needed because in py 3.x, tie-breaking fails on the nodes.
        # this way, insertion order is preserved if the weights are the same
        q = [[inf, i, n, []] for i, n in enumerate(nodes) if n is not fromsys]
        q.insert(0, [0, -1, fromsys, []])

        # this dict will store the distance to node from ``fromsys`` and the path
        result = {}

        # definitely starts as a valid heap because of the insert line; from the
        # node to itself is always the shortest distance
        while len(q) > 0:
            d, orderi, n, path = heapq.heappop(q)

            if d == inf:
                # everything left is unreachable from fromsys, just copy them to
                # the results and jump out of the loop
                result[n] = (None, d)
                for d, orderi, n, path in q:
                    result[n] = (None, d)
                break
            else:
                result[n] = (path, d)
                path.append(n)
                if n not in edgeweights:
                    # this is a system that can be transformed to, but not from.
                    continue
                for n2 in edgeweights[n]:
                    if n2 not in result:  # already visited
                        # find where n2 is in the heap
                        for i in range(len(q)):
                            if q[i][2] == n2:
                                break
                        else:
                            raise ValueError(
                                "n2 not in heap - this should be impossible!"
                            )

                        newd = d + edgeweights[n][n2]
                        if newd < q[i][0]:
                            q[i][0] = newd
                            q[i][3] = list(path)
                            heapq.heapify(q)

        # cache for later use
        self._shortestpaths[fromsys] = result
        return result[tosys]

    def get_transform(self, fromsys, tosys):
        """Generates and returns the CompositeTransform for a transformation
        between two coordinate systems.

        Parameters
        ----------
        fromsys : class
            The coordinate frame class to start from.
        tosys : class
            The coordinate frame class to transform into.

        Returns
        -------
        trans : `~astropy.coordinates.CompositeTransform` or None
            If there is a path from ``fromsys`` to ``tosys``, this is a
            transform object for that path.   If no path could be found, this is
            `None`.

        Notes
        -----
        A `~astropy.coordinates.CompositeTransform` is always returned, because
        `~astropy.coordinates.CompositeTransform` is slightly more adaptable in
        the way it can be called than other transform classes. Specifically, it
        takes care of intermediate steps of transformations in a way that is
        consistent with 1-hop transformations.

        """
        if not inspect.isclass(fromsys):
            raise TypeError("fromsys is not a class")
        if not inspect.isclass(tosys):
            raise TypeError("tosys is not a class")

        path, distance = self.find_shortest_path(fromsys, tosys)

        if path is None:
            return None

        transforms = []
        currsys = fromsys
        for p in path[1:]:  # first element is fromsys so we skip it
            transforms.append(self._graph[currsys][p])
            currsys = p

        fttuple = (fromsys, tosys)
        if fttuple not in self._composite_cache:
            comptrans = CompositeTransform(
                transforms, fromsys, tosys, register_graph=False
            )
            self._composite_cache[fttuple] = comptrans
        return self._composite_cache[fttuple]

    def lookup_name(self, name):
        """
        Tries to locate the coordinate class with the provided alias.

        Parameters
        ----------
        name : str
            The alias to look up.

        Returns
        -------
        `BaseCoordinateFrame` subclass
            The coordinate class corresponding to the ``name`` or `None` if
            no such class exists.
        """
        return self._cached_names.get(name, None)

    def get_names(self):
        """
        Returns all available transform names. They will all be
        valid arguments to `lookup_name`.

        Returns
        -------
        nms : list
            The aliases for coordinate systems.
        """
        return list(self._cached_names.keys())

def to_dot_graph(
        self,
        priorities=True,
        addnodes=[],
        savefn=None,
        savelayout="plain",
        saveformat=None,
        color_edges=True,
    ):
        """
        Converts this transform graph to the graphviz_ DOT format.

        Optionally saves it (requires _ be installed and on your path).

        .. _graphviz: http://www.graphviz.org/

        Parameters
        ----------
        priorities : bool
            If , show the priority values for each transform.  Otherwise,
            the will not be included in the graph.
        addnodes : sequence of str
            Additional coordinate systems to add (this can include systems
            already in the transform graph, but they will only appear once).
        savefn : None or str
            The file name to save this graph to or  to not save
            to a file.
        savelayout : str
            The graphviz program to use to layout the graph (see
            graphviz_ for details) or 'plain' to just save the DOT graph
            content. Ignored if savefn is .
        saveformat : str
            The graphviz output format. (e.g. the -Txxx option for
            the command line program - see graphviz docs for details).
            Ignored if savefn is .
        color_edges : bool
            Color the edges between two nodes (frames) based on the type of
            transform. FunctionTransform: red, StaticMatrixTransform:
            blue, DynamicMatrixTransform: green.

        Returns
        -------
        dotgraph : str
            A string with the DOT format graph.
        """
        # ... [rest of the method implementation] ...

        dotgraph = "\n".join(lines)

        if savefn is not None:
            # Validate savelayout
            allowed_layouts = ['plain', 'dot', 'neato', 'twopi', 'circo', 'fdp', 'sfdp']
            if savelayout not in allowed_layouts:
                raise ValueError(f"Invalid savelayout. Allowed values are: {', '.join(allowed_layouts)}")

            # Use subprocess.run with a list of arguments instead of shell=True
            import subprocess
            import shlex

            if savelayout == 'plain':
                with open(savefn, 'w') as f:
                    f.write(dotgraph)
            else:
                cmd = [savelayout]
                if saveformat:
                    cmd.extend(['-T', saveformat])
                cmd.extend(['-o', savefn])

                try:
                    result = subprocess.run(cmd, input=dotgraph.encode(), check=True, capture_output=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error running {savelayout}: {e}")
                    print(f"stdout: {e.stdout.decode()}")
                    print(f"stderr: {e.stderr.decode()}")
                    raise

        return dotgraph
