package util;

import t9.abstracts.net.*;

using StringTools;

typedef DockerUrlBlob = {
	var repository :String;
	@:optional var registry :Host;
	@:optional var tag :String;
}

/**
 * Docker URLs are confusing.
 * Assuming:
 * [registry/][namespace/][repository]:<tag>
 * or
 * [registry/]<name>:<tag>
 */

abstract DockerUrl(String) to String from String
{
	inline public function new (s :String)
		this = s;

	public var tag(get, never) :String;
	public var registry(get, never) :Host;
	public var repository(get, never) :String;

	inline public function noTag() :DockerUrl
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		u.tag = null;
		return DockerUrlTools.joinDockerUrl(u);
	}

	inline public function blob() :DockerUrlBlob
	{
		return DockerUrlTools.parseDockerUrl(this);
	}

	inline public function get_repository() :String
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		return u.repository;
	}

	inline public function set_tag(tag :String) :String
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		u.tag = tag;
		this = DockerUrlTools.joinDockerUrl(u);
		return tag;
	}

	inline public function get_tag() :String
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		return u.tag;
	}

	inline public function set_registry(registry :Host) :Host
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		u.registry = registry;
		this = DockerUrlTools.joinDockerUrl(u);
		return tag;
	}

	inline public function get_registry() :Host
	{
		var u = DockerUrlTools.parseDockerUrl(this);
		return u.registry;
	}
}

class DockerUrlTools
{
	public static function matches(a :DockerUrl, b :DockerUrl) :Bool
	{
		if (a.repository == b.repository) {
			var tagA = a.tag;
			var tagB = b.tag;
			return tagA == null || tagB == null ? true : (tagA == tagB);
		} else {
			return false;
		}
	}

	public static function joinDockerUrl(u :DockerUrlBlob, ?includeTag :Bool = true) :String
	{
		return (u.registry != null ? u.registry + '/' : '')
			+ u.repository
			+ (u.tag != null && includeTag ? ':' + u.tag : '');
	}

	public static function parseDockerUrl(s :String) :DockerUrlBlob
	{
		s = s.trim();
		var r = ~/(.*\/)?([a-z0-9_-]+)(:[a-z0-9_\.-]+)?/i;
		r.match(s);
		var registryAndNamespace = r.matched(1);
		var repository = r.matched(2);
		var tag = r.matched(3);
		if (tag != null) {
			tag = tag.substr(1);
		}
		registryAndNamespace = registryAndNamespace != null ?registryAndNamespace.substr(0, registryAndNamespace.length - 1) : null;
		var namespace :String = null;
		var registry :Host = null;
		if (registryAndNamespace != null) {
			var tokens = registryAndNamespace.split('/');
			if (tokens.length > 1) {
				namespace = tokens.pop();
				registry = tokens.length > 0 ? tokens.join('/') : null;
			} else {
				//If the registry and namespace does not contain /
				//and there's no '.'/':' then there's no registry
				if (registryAndNamespace.indexOf('.') > -1 || registryAndNamespace.indexOf(':') > -1) {
					registry = registryAndNamespace;
				} else {
					namespace = registryAndNamespace;
				}
			}
		}

		var url :DockerUrlBlob = {
			repository: namespace == null ? repository : '${namespace}/${repository}',
		}
		if (tag != null) {
			url.tag = tag;
		}
		if (registry != null) {
			url.registry = registry;
		}
		return url;
	}

	public static function getRepository(u :DockerUrlBlob, ?includeTag :Bool = true) :String
	{
		return (u.registry != null ? u.registry + '/' : '')
			+ u.repository
			+ (u.tag != null && includeTag ? ':' + u.tag : '');
	}
}
