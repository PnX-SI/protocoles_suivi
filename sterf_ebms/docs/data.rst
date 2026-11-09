Data documentation
==================

This page is mainly destined to the folks who will integrate exports produced by
this module. As this target audience is mostly english-speaking, this section is
in English. Another target audience is Sterf data holders looking for an
adequate data format to send to the eBMS: the format presented here can be used
as a reference.

We often refer to `Indicia`_, which is the backend used by the eBMS platform to
store data. Some technical choices taken with this module cannot be explained
without having this information, as some redundant or weirdly formatted data is
exported in a specific way so that importing them into Indicia becomes a process
involving as few manual process as possible. We took the greatest care while
working with the UKCEH to understand the way Indicia stores data to ensure
concepts stay meaningful when exported data ends up in the eBMS.

The `Indicia import process`_ is documented on the Indicia documentation.

.. _Indicia: https://indicia-docs.readthedocs.io/en/latest/
.. _Indicia import process: https://indicia-docs.readthedocs.io/en/latest/administrating/importing-transect.html


Data flow
---------

The expected flow for Sterf-eBMS data is the following:

1. Sterfists produce data and they save it using this module.
2. This data is regularly exported by the module administrator and sent to an
   eBMS contact.
3. The data is integrated in the eBMS database (actually Indicia); thanks to
   preparatory work and a single module, there is minimal friction for
   integration.
4. On a regular basis, the `MNHN`_ exports or receives from the eBMS platform
   the French data that has been submitted.
5. The data is integrated in national database, thus at the disposal of the
   original actors.

.. _MNHN: https://www.mnhn.fr/en

.. admonition:: I have exported data from this module, who do I send it to?

   Sending your data to the eBMS is covered in the :ref:`admin documentation
   <send_my_data>`.

When observations are produced, GeoNature immediately attaches an UUID to each
one. This UUID is shared in all steps of this flow, thus preventing data
duplication.


What to expect in exports?
--------------------------

Files
^^^^^

The module can produce 4 files, one per export type:

* Transects data: descriptions of the eBMS transects.
* Sections data: descriptions of the eBMS sections.
* Transect visits: visit data grouped by transect.
* Section observations: observations grouped by section visits.

Both transect and section data is straightforwardly exported as there is a
matching concept in Indicia: both are locations, and transects are parent
locations of sections.

Transect visits and sections observations require some internal work to be
exported. At the GeoNature level, the data hierarchy implies that visit data is
related to a section:

#. A transect contains sections.
#. A section can have visits.
#. An observation is made during a visit.

But at the Indicia level, the data hierarchy looks more like:

#. A transect contains sections (or more generally, locations can have parent
   locations).
#. A transect can be visited: a visit is called a sample, and visit data is
   related to the transect.
#. For each section, observations are grouped in a sub-sample, the section
   visit.

In practice, this means that GeoNature “section visits” must be converted into
“transect visits”. This is done using averages: section visits can define
different temperatures, so the transect visit use the average of all section
visits temperatures.

.. important::

   **Each row of all these exports always contain an UUID** that can be used as
   “external key” when importing them into Indicia to avoid item duplication.
   Identifiers for the GeoNature concepts (transects, sections, visits,
   observations) are transmitted as well as for the Indicia concepts
   (transects, sections, transect visits, section observations) so that all
   concepts always remain uniquely identifiable.

.. danger::

   Because UUIDs are the only way to prevent data duplication, as a GeoNature
   administrator, you must avoid deleting and recreating transects, sections or
   any entity as it will generate a new UUID. Modifying an entity's UUID, e.g.
   to restore a replaced UUID, requires manual database operations.

Column names
^^^^^^^^^^^^

Some columns name contain spaces instead of underscore: this is expected
behaviour, do not attempt to replace these to improve the export. Indeed, the
Indicia import tool automatically maps CSV column name to the adequate database
column using the column name. In some specific cases, the mapping does not work
if the columns names uses underscores.

Habitats and other terms
^^^^^^^^^^^^^^^^^^^^^^^^

Sterf habitats use a different nomenclature than the eBMS. We created a mapping
so that each Sterf habitat can be mapped to, at least, a principal habitat, and
in some cases, the section's linear habitat as well. The details of the mapping
can be found in the ``ref_habitats.cor_sterf_to_ebms`` table created in the
``exports/csv/export_csv.sql`` file of the module.

Wind speed uses the Beaufort scale but is limited to level 6. In the same vein,
temperatures are Celsius degrees and cannot go above 40°.

In some cases such as with wind speeds, these values are not transmitted raw but
as a corresponding eBMS term list value, e.g. the column wind speed does not
contain a plain ``3`` for the level 3 but rather the string ``3. Leaves and
twigs in slight motion``. This helps to streamline the import process.

.. note::

   Indicia does allow storing metadata other than what is defined by the eBMS
   platform, but this module currently cannot use this functionality. As a
   result, metadata that does not fit into eBMS columns would be lost. To
   prevent this, for data we consider valuable, it has been added in the comment
   section, and the following exports sections will describe the related
   formats. This way, Sterf producers can retrieve some interesting information,
   such as the original habitat, down the data pipeline.

Geometries
^^^^^^^^^^

Geometric data is always converted to the expected CRS, but we still add columns
to note the SRID next to each geometry column. The goal is to avoid having
geometric data without its SRID in the wild.


Transects export
----------------

The transects exports contain the following columns:

``external_key``
    Transect UUID.
``name``
    Transect name.
``code``
    Transect code, if it looks like an EBMS transect code (i.e. it starts with
    ``EBMS:``). This can be used to help investigate duplicated transects, or to
    split the export between the sections identified by external keys and those
    identified by code.
``centroid_sref``
    Centroid of the transect as decimal degrees. SRID is always 4326.
``centroid_sref_srid``
    Always 4326.
``comment``
    An optional description of the transect.
    This column also contains the original STOC habitat.
``boundary_geom``
    WKT of the transect geometry. This may or may not be useful as the sections
    geometry is what ultimately matters. SRID is always 3857.
``boundary_geom_srid``
    Always 3857.
``sensitive``
    Whether this transect is sensitive and should be hidden from public views.
    "True" or "False".
``no_of_sections``
    Number of sections in this transect.
``transect_width_m``
    Width of the sections.
``principal_habitat``
    Principal habitat, using the eBMS term list.
``2nd_habitat``
    Secondary habitat (optional).
``principal_land_tenure``
    Principal land tenure, using the eBMS term list.
``2nd_land_tenure``
    Secondary land tenure.
``principal_land_management``
    Principal land management, using the eBMS term list.
``2nd_land_management``
    Secondary land management.
``notes_on_habitat_land_management_and_tenure``
    The name says it all!
``country``
    Always 216023, hardcoded value for France.

.. admonition:: Metadata

   The original STOC habitat is stored in the comment column. On their own line,
   it starts with ``Habitat principal :`` and/or ``Habitat secondaire :``,
   followed by the 4-character STOC habitat code, e.g. Ec3b.


Sections export
---------------

The sections exports contain the following columns:

``external_key``
    Section UUID.
``name``
    Section name, if any.
``code``
    Section code, if any. Users are prompted to use eBMS-like codes such as S1,
    S2, etc, but this is a free text input.
``parent_location_external_key``
    Transect UUID that this section belongs to.
``centroid_sref``
    Centroid of the section as decimal degrees. SRID is always 4326.
``centroid_sref_srid``
    Always 4326.
``comment``
    User comment.
``boundary_geom``
    WKT of the section (a LINESTRING). SRID is always 3857.
``boundary_geom_srid``
    Always 3857.
``section_length_m``
    The length of the section.
``primary_habitat_present``
    The primary habitat on this section; it may or may not be different than the
    transect primary habitat.
``2nd_habitat_present``
    The secondary habitat on this section; it may or may not be different than
    the transect secondary habitat.
``linear_habitat``
    The linear habitat, using the eBMS term list.
``primary_land_management_present``
    The primary land management present on the section.
``2nd_land_management_present``
    The secondary land management present on the section.
``notes_on_land_use_and_management``
    User comments on the land management.

.. admonition:: Metadata

   The original STOC habitat is stored in the comment column, just like for
   transects.


Transect visits export
----------------------

The transect visits exports contain the following columns:

``external_key``
    Visit globally unique identifier (GUID). As transect visits correspond to
    the combination of all section visits for the same day on a specific
    transect, this GUID is formed of the transect UUID and the visits date, e.g.
    ``ba2234f0-ffbb-4532-bf49-81a009ae031f-2025-05-02``.
``location external key``
    Transect UUID. Redundant with the preceding GUID but allows easier imports.
``location_name``
    Transect name.
``grid ref``
    Centroid of the transect (see ``centroid_sref`` in the transect exports).
``grid_ref_srid``
    Always 4326.
``date``
    The visit date, formatted as YYYY-MM-DD.
``start_time``
    The start hour of the first section walk that day.
``end_time``
    The end hour of the last section walk that day.
``recorder_name``
    The observer name, or names if several, each on their own line.
``comment``
    User comments regarding the visit. Because the export aggregates section
    visits, the comment is the concatenation of section visit comments, each
    line starting with the section code.
``temp_deg_c``
    Average temperature during the visit. Max 40°C.
``%_cloud``
    Average cloud cover during the visit, as a percentage.
``wind_speed``
    Average wind speed during the visit, as a Beaufort scale level. Max at 6.
``any_butterflies_?``
    Boolean: 1 if any butterflies were seen during the visit, 0 otherwise.
    This is a user-set value and may not be consistent with the actual number of
    observations included in the sample.
``num_sections_visited``
    Number of sections visited during this transect visit. Mostly for internal
    use.

.. admonition:: Metadata

   Sterf users often report the floral cover of the transects they are visiting,
   which is a rough estimate of the perceived abundance and diversity of flowers
   found at the time of the visit. If the flover cover for a section visit has
   been reported, a corresponding code will be appended to the comment line
   regarding the section visit in the comment column.

   For example, during a transect visit composed of three sections named S1, S2
   and S3, the user commented nothing for the first visit and did not report
   the floral cover, commented something for the second visit about debris but
   did not report floral cover, and comment something about the sun for the
   third visit and reported a floral cover. The comment value would look like::

      S2 : présence de nombreux débris sur le chemin
      S3 : très chaud !, FC_2_AVERAGE

   The floral cover is added as a section comment even if the section visit has
   no written comment, e.g. ``S1 : FC_1_NONE``.

   The floral cover nomenclature is:

   ==================== =======
   Code                 Meaning
   ==================== =======
   FC_1_NONE            No or very few flowers (less than 5% of the surface).
   FC_2_AVERAGE         Some flowers (between 5 and 20% of the surface).
   FC_3_COVERED         Flowered (more than 20% of the surface).
   FC_4_COVERED_COLORED Flowered and with varied flower colors.
   ==================== =======


Section observations export
---------------------------

The section observations exports contain the following columns:

``occurrence external key``
    Occurrence UUID. This is the French SINP UUID for this occurrence.
``sample external key``
    Section visit UUID.
``parent_sample_external_key``
    Transect visit GUID, as used in the transect visits export.
``location external key``
    Section UUID.
``location_name``
    Section name.
``grid ref``
    Centroid of the section (see ``centroid_sref`` in the section exports).
``grid_ref_srid``
    Always 4326.
``date``
    Visit date.
``reliability``
    Whether the abundance count is reliable or not, using the eBMS term list.
``taxon_name``
    Taxon scientific name, without the author part.
``abundance_count``
    Count of specimens. Always strictly positive, absences are not reported.
``occurrence comment``
    User comment about the specific occurrence. It always also contains the
    TaxRef CD_NOM of the taxon so that it can be unambiguously identified.

.. admonition:: Metadata

   The CD_NOM is always present in the comment field, with the ``CD_NOM``
   keyword followed by the value (no colon), e.g. ``CD_NOM 53979`` for a
   *Lycaena dispar* occurrence.
