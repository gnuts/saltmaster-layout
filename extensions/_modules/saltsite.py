#!/usr/bin/python

'''
Saltsite execution module
'''

import pprint
import copy
import collections
import logging

# Import Salt libs
import salt
import salt.version
import salt.loader

log = logging.getLogger(__name__)

# idea stolen from:
# http://stackoverflow.com/questions/3232943/update-value-of-a-nested-dictionary-of-varying-depth/3233356#3233356
def merge(dict_a, dict_b, deepcopy=True, maxdepth=0):
  """
  Merge two nested dictionaries.

  This combines dict_a and dict_b and recursively merges contents of embedded, nested
  dicts, lists and keys.
  Dicts and lists are merged, everything else is overwritten.

  if a scalar is in both dicts, dict_b overwrites dict_a

  if deepcopy is true, the data structures are deepcopied, the original data is not modified.

  TODO:

  * implement maxdepth
  """
  if deepcopy:
    a = copy.deepcopy(dict_a)
    b = copy.deepcopy(dict_b)
  else:
    a = dict_a
    b = dict_b

  for key, val in b.iteritems():
    if isinstance(val, collections.Mapping):
      tmp = merge(a.get(key, {}), val)
      a[key] = tmp
    elif isinstance(val, list):
      a[key] = (a.get(key, []) + val)
    else:
      a[key] = b[key]
  return a


def applydefaults(data, defkey='_defaults', deepcopy=True, maxdepth=0) :
  """
  Recursively traverse dictionary data and merge contents of defaults into all
  sub-dictionaries on the same level.

  The defaults are stored in a specific key "defkey" on each level.
  The defkey-dictionary is removed from the result.

  TODO:

  * implement maxdepth
  """

  if deepcopy:
    data2 = copy.deepcopy(data)
  else:
    data2 = data

  if defkey in data2:
    defaults = data2.pop(defkey)
    for key, val in data2.iteritems():
      if isinstance(val, collections.Mapping):
        data2[key] = merge(defaults, data2[key], deepcopy=True)

  for key, val in data2.iteritems():
    if isinstance(val, collections.Mapping):
      applydefaults(val,defkey,deepcopy=deepcopy, maxdepth=maxdepth)

  return data2



def dfqdn():
  """
  Returns the dfqdn of this host

  The dfqdn is the fqdn of a host with dots '.' replaced by dashes '-'

  host.example.org becomes host-example-org
  """
  mydfqdn = __salt__["grains.get"]("id")
  return dfqdn.replace(".","-")

def groupmerge(key=False, pillar=False, branchkey=False, globaldefkey="defaults", defkey="_defaults", groupkey="groups", defaults=False ):
  """
  Merge a branch of multiple pillar hierarchies into one.
  Apply global defaults. Apply local defaults.

  Global defaults are default settings, which are are placed in exactly the
  same hierarchy as the normal pillar data, except that everything is below
  "defaults".

  "key" is the name of a key on the first level of the resulting pillar.
  If "key" is set, only the value of this key will be returned.
  If it is not set, the whole resulting, merged pillar is returned

  "defaults" can be a dictionary that is used as base data. everything is mergend on top of that.
  This is useful for module specific core defaults.

  If pillar is not given, the minions pillar is used.
  If branchkey is not given, the dfqdn is constructed and used.

  The result is a new dictionary, merged from all groups and the host.
  Defaults will be applied and all default subdictionaries will be removed.

  e.g.::

    pillar1:
        branch1:
            test:
                - data1
                - data2
            subdata:
                _defaults:
                    x:1
                    y:1
                set1:
                    x:2
                set2:
                    y:2
                set3:

        defaults:
            test:
                - data3
                - data4
            subdata:
                set4:
                    x:3
               

  Result::

    pillar1:
        branch1:
            test:
                - data1
                - data2
                - data3
                - data4
            subdata:
                set1:
                    x:2
                    y:1
                set2:
                    x:1
                    y:2
                set3:
                    x:1
                    y:1
                set4:
                    x:3
                    y:1



  """
  log.trace('groupmerge!')
  
  result = {}
  groups = []
  branch = {}

  if not pillar:
    log.trace("using minion pillar")
    pillar = __salt__["pillar.items"]()

  #log.trace("pillar:"+pprint.pformat(pillar))

  if not branchkey:
    branchkey = __salt__["grains.get"]("id")
    branchkey = branchkey.replace(".","-")
    log.trace("using dfqdn as branch key: "+branchkey)

  if defaults:
    result = merge({branchkey: defaults}, result, deepcopy=True) 

  branch = pillar.get(branchkey,{})

  if "groups" in branch:
    log.trace('found groups')
    groups=branch.pop("groups")

  for g in groups+[branchkey]:
    subpillar = pillar.get(g,{})
    result = merge(result,subpillar,deepcopy=False)

  # now result contains a merge of all group pillars.
  # apply globaldefaults
  globaldefaults = {}
  if globaldefkey in result:
    globaldefaults = result.pop(globaldefkey)
    result = merge(result,globaldefaults,deepcopy=False)

  # finally, apply subdict defaults
  #log.trace("dump:"+pprint.pformat(result))
  result = applydefaults(result, defkey=defkey,deepcopy=False)

  if key:
    log.trace("return key only:"+key)
    result = result.get(key,"ERROR: key "+key+" not found")

  log.trace("result:"+pprint.pformat(result))

  return result 



