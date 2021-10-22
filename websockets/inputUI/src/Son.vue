<template>
	<div>
	   <div >
		------------------------
		<br>
		
			this 
		{{ place }}
		
		 <br>
		  --------------------------
		  <br>
		 <slot>  </slot>
	
	   </div>
	   
	</div>
	
</template>

<script>
	export default {

		props: [ 'place' ],
		data() {
			return {
				test: "only a test",
				show: sessionStorage.username=='james'
			}
		}  
  
  }

</script>

<style>
</style>
